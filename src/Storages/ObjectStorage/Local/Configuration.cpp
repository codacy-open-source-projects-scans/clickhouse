#include <Core/Settings.h>
#include <Interpreters/Context.h>
#include <Interpreters/evaluateConstantExpression.h>
#include <Storages/ObjectStorage/Local/Configuration.h>
#include <Storages/checkAndGetLiteralArgument.h>
#include "Common/NamedCollections/NamedCollections.h"


namespace DB
{

namespace ErrorCodes
{
extern const int NUMBER_OF_ARGUMENTS_DOESNT_MATCH;
}

void StorageLocalConfiguration::fromNamedCollection(const NamedCollection & collection, ContextPtr)
{
    path = collection.get<String>("path");
    format = collection.getOrDefault<String>("format", "auto");
    compression_method = collection.getOrDefault<String>("compression_method", collection.getOrDefault<String>("compression", "auto"));
    structure = collection.getOrDefault<String>("structure", "auto");
    paths = {path};
}


void StorageLocalConfiguration::fromAST(ASTs & args, ContextPtr context, bool with_structure)
{
    const size_t max_args_num = with_structure ? 4 : 3;
    if (args.empty() || args.size() > max_args_num)
    {
        throw Exception(ErrorCodes::NUMBER_OF_ARGUMENTS_DOESNT_MATCH, "Expected not more than {} arguments", max_args_num);
    }

    for (auto & arg : args)
        arg = evaluateConstantExpressionOrIdentifierAsLiteral(arg, context);

    path = checkAndGetLiteralArgument<String>(args[0], "path");

    if (args.size() > 1)
    {
        format = checkAndGetLiteralArgument<String>(args[1], "format_name");
    }

    if (with_structure)
    {
        if (args.size() > 2)
        {
            structure = checkAndGetLiteralArgument<String>(args[2], "structure");
        }
        if (args.size() > 3)
        {
            compression_method = checkAndGetLiteralArgument<String>(args[3], "compression_method");
        }
    }
    else if (args.size() > 2)
    {
        compression_method = checkAndGetLiteralArgument<String>(args[2], "compression_method");
    }
    paths = {path};
}

StorageObjectStorage::QuerySettings StorageLocalConfiguration::getQuerySettings(const ContextPtr & context) const
{
    const auto & settings = context->getSettingsRef();
    return StorageObjectStorage::QuerySettings{
        .truncate_on_insert = settings.engine_file_truncate_on_insert,
        .create_new_file_on_insert = false,
        .schema_inference_use_cache = settings.schema_inference_use_cache_for_file,
        .schema_inference_mode = settings.schema_inference_mode,
        .skip_empty_files = settings.engine_file_skip_empty_files,
        .list_object_keys_size = 0,
        .throw_on_zero_files_match = false,
        .ignore_non_existent_file = false};
}

}