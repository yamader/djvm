module djvm.loader;

import std;
import djvm.libs;
import djvm.classfile;

alias dbg = writeln;

auto unpack(T)(ubyte[] v) {
  auto fixed = cast(ubyte[T.sizeof])v[0 .. T.sizeof];
  return fixed.bigEndianToNative!T;
}

auto loadClassFile(string path) {
  auto f = File(path);
  auto buf = f.rawRead(new ubyte[f.size]);
  auto cf = new Dyns!ClassFile(buf.ptr);

  // constant_pool
  auto cp_n = cf.constant_pool_count.val.unpack!ushort - 1;
  dbg("constant pools count: ", cp_n + 1);
  foreach(i; 0 .. cp_n) {
    auto cpInfo = new Dyns!cp_info(cf.constant_pool.ptr + cf.constant_pool.size);
    final switch(cpInfo.tag.val) with(CONSTANT) {
      case Class:
      case Fieldref:
      case Methodref:
      case InterfaceMethodref:
      case String:
      case Integer:
      case Float:
      case Long:
      case Double:
      case NameAndType:
      case Utf8:
      case MethodHandle:
      case MethodType:
      case InvokeDynamic:
    }
  }
}
