---
slug: /ja/sql-reference/statements/select/sample
sidebar_label: SAMPLE
---

# SAMPLE句

`SAMPLE`句は、近似の`SELECT`クエリ処理を可能にします。

データサンプリングが有効になっている場合、クエリはすべてのデータに対して実行されるのではなく、データの一部（サンプル）のみに対して実行されます。例えば、すべての訪問の統計を計算する必要がある場合、すべての訪問の10分の1のデータに対してクエリを実行し、その結果を10倍するだけで十分です。

近似クエリ処理が有用なケースは以下の通りです：

- 厳格なレイテンシ要件（例えば100ms未満）があるが、これを満たすための追加のハードウェアリソースのコストを正当化できない場合。
- 生データが正確でないので、近似が品質を明らかに劣化させることはない場合。
- ビジネス要件が近似結果を目標としている場合（コスト効果のため、または正確な結果をプレミアムユーザーに提供するため）。

:::note    
サンプリングは、[MergeTree](../../../engines/table-engines/mergetree-family/mergetree.md)ファミリーのテーブルでのみ使用でき、テーブル作成時にサンプリング式が指定された場合のみ使用できます（[MergeTreeエンジン](../../../engines/table-engines/mergetree-family/mergetree.md#table_engine-mergetree-creating-a-table)を参照）。
:::

データサンプリングの特長は以下の通りです：

- データサンプリングは決定的なメカニズムです。同じ`SELECT .. SAMPLE`クエリの結果は常に同じです。
- サンプリングは異なるテーブルでも一貫して機能します。単一のサンプリングキーを持つテーブルの場合、同じ係数を持つサンプルは常に可能なデータの同じ部分集合を選択します。例えば、ユーザーIDのサンプルは、異なるテーブルから可能なすべてのユーザーIDの同じ部分集合を持つ行を選択します。これにより、[IN](../../../sql-reference/operators/in.md)句のサブクエリでサンプルを使用できます。また、[JOIN](../../../sql-reference/statements/select/join.md)句を使用してサンプルを結合することができます。
- サンプリングは、ディスクからのデータ読み取りを減少させます。サンプリングキーを正しく指定する必要があることに注意してください。詳細は[MergeTreeテーブルの作成](../../../engines/table-engines/mergetree-family/mergetree.md#table_engine-mergetree-creating-a-table)を参照してください。

`SAMPLE`句のサポートされている構文は以下の通りです：

| SAMPLE 句構文 | 説明                                                                                                                                                                                                                                    |
|----------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `SAMPLE k`   | ここで`k`は0から1の数字です。クエリはデータの`k`部分に対して実行されます。例えば、`SAMPLE 0.1`はデータの10%でクエリを実行します。[詳細を読む](#sample-k)                                                                             |
| `SAMPLE n`    | ここで`n`は十分に大きい整数です。クエリは少なくとも`n`行のサンプルで実行されます（ただし、それより大幅に多くはありません）。例えば、`SAMPLE 10000000`は最低でも10,000,000行でクエリを実行します。[詳細を読む](#sample-n) |
| `SAMPLE k OFFSET m`  | ここで`k`および`m`は0から1の数字です。クエリはデータの`k`部分のサンプルで実行されます。使用されるデータは`m`部分だけオフセットされます。[詳細を読む](#sample-k-offset-m)                                           |

## SAMPLE K

ここで`k`は0から1の数字（小数および分数の表記がサポートされています）です。例えば、`SAMPLE 1/2`または`SAMPLE 0.5`。

`SAMPLE k`句では、データの`k`部分のサンプルからデータを抽出します。以下に例を示します：

``` sql
SELECT
    Title,
    count() * 10 AS PageViews
FROM hits_distributed
SAMPLE 0.1
WHERE
    CounterID = 34
GROUP BY Title
ORDER BY PageViews DESC LIMIT 1000
```

この例では、クエリはデータの0.1（10%）のサンプルで実行されます。集計関数の値は自動的に補正されないため、近似結果を得るには`count()`の値を手動で10倍する必要があります。

## SAMPLE N

ここで`n`は十分に大きい整数です。例えば、`SAMPLE 10000000`。

この場合、クエリは少なくとも`n`行のサンプルで実行されます（ただし、それより大幅に多くはありません）。例えば、`SAMPLE 10000000`は最低でも10,000,000行でクエリを実行します。

データ読み取りの最小単位は1つのグラニュールであるため（そのサイズは`index_granularity`設定で設定されます）、グラニュールのサイズよりも大きいサンプルを設定することが意味があります。

`SAMPLE n`句を使用する場合、処理されたデータの相対的な割合を把握することはできません。したがって、集計関数をどれだけ倍にするべきかを知ることはできません。近似の結果を得るためには、仮想カラム`_sample_factor`を使用します。

`_sample_factor`カラムは動的に計算される相対的な係数を含みます。このカラムは、サンプリングキーを指定してテーブルを[作成](../../../engines/table-engines/mergetree-family/mergetree.md#table_engine-mergetree-creating-a-table)する際に自動的に作成されます。`_sample_factor`カラムの使用例を以下に示します。

サイト訪問の統計を含むテーブル`visits`を考えます。最初の例はページビュー数を計算する方法を示しています：

``` sql
SELECT sum(PageViews * _sample_factor)
FROM visits
SAMPLE 10000000
```

次の例は、訪問の総数を計算する方法を示しています：

``` sql
SELECT sum(_sample_factor)
FROM visits
SAMPLE 10000000
```

以下の例は、セッションの平均継続時間を計算する方法を示しています。平均値を計算するには、相対的係数を使用する必要はありません。

``` sql
SELECT avg(Duration)
FROM visits
SAMPLE 10000000
```

## SAMPLE K OFFSET M

ここで`k`および`m`は0から1の数字です。以下に例を示します。

**例 1**

``` sql
SAMPLE 1/10
```

この例では、すべてのデータの1/10のサンプルです：

`[++------------]`

**例 2**

``` sql
SAMPLE 1/10 OFFSET 1/2
```

ここで、データの後半から10%のサンプルが取られます。

`[------++------]`