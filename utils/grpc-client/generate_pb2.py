#!/usr/bin/env python3

# This is a helper utility.
# It generates files in the "pb2" folder using the protocol buffer compiler.
# This script must be called manually after any change pf "clickhouse_grpc.proto"

import grpc_tools  # pip3 install grpcio-tools

import os, shutil, subprocess


# Settings.
script_path = os.path.realpath(__file__)
script_name = os.path.basename(script_path)
script_dir = os.path.dirname(script_path)
root_dir = os.path.abspath(os.path.join(script_dir, "../.."))

grpc_proto_dir = os.path.abspath(os.path.join(root_dir, "src/Server/grpc_protos"))
grpc_proto_filename = "clickhouse_grpc.proto"

# Files in the "pb2" folder which will be generated by this script.
pb2_filenames = ["clickhouse_grpc_pb2.py", "clickhouse_grpc_pb2_grpc.py"]
pb2_dir = os.path.join(script_dir, "pb2")


# Processes the protobuf schema with the protocol buffer compiler and generates the "pb2" folder.
def generate_pb2():
    print(f"Generating files:")
    for pb2_filename in pb2_filenames:
        print(os.path.join(pb2_dir, pb2_filename))

    os.makedirs(pb2_dir, exist_ok=True)

    cmd = [
        "python3",
        "-m",
        "grpc_tools.protoc",
        "-I" + grpc_proto_dir,
        "--python_out=" + pb2_dir,
        "--grpc_python_out=" + pb2_dir,
        os.path.join(grpc_proto_dir, grpc_proto_filename),
    ]
    subprocess.run(cmd)

    for pb2_filename in pb2_filenames:
        assert os.path.exists(os.path.join(pb2_dir, pb2_filename))
    print("Done! (generate_pb2)")


# MAIN
if __name__ == "__main__":
    generate_pb2()