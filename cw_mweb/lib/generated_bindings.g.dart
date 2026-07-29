// GENERATED CODE - DO NOT MODIFY BY HAND
// Stub for ffigen-generated bindings

import 'dart:ffi';

class MWebFlutter {
  MWebFlutter(DynamicLibrary lib);

  int StartServer(Pointer<Char> chain, Pointer<Char> dataDir, Pointer<Char> nodeUri, Pointer<Pointer<Char>> errMsg) => 0;
  void StopServer() {}
  Pointer<Char> Addresses(Pointer<Void> scanSecret, int scanSecretLen, Pointer<Void> spendPub, int spendPubLen, int fromIndex, int toIndex) => nullptr;
}
