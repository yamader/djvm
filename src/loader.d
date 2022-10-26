module djvm.loader;

import std;
import djvm.libs;
import djvm.classfile;

alias dbg = writeln;
noreturn NIY() {
  import core.stdc.stdlib;
  stderr.writeln("\x1b[1;31mNot implemented yet.\x1b[0m");
  exit(1);
}

auto unpack(T)(ubyte[] v) {
  auto fixed = cast(ubyte[T.sizeof])v[0 .. T.sizeof];
  return fixed.bigEndianToNative!T;
}

auto loadClassFile(string path) {
  auto f = File(path);
  auto fbuf = f.rawRead(new ubyte[f.size]);
  auto cf = new Dyns!ClassFile(fbuf.ptr);
  dbg("loading file: ", path);

  // constant_pool
  void*[] cp; //
  auto cp_n = cf.constant_pool_count.val.unpack!ushort - 1;
  dbg("constant pools count: ", cp_n);
  foreach(i; 0 .. cp_n) {
    auto cpInfo = new Dyns!cp_info(cf.constant_pool.ptr + cf.constant_pool.size);
    dbg("\n  constant pool [", i + 1, "]: ", cast(CONSTANT)cpInfo.tag.val);
    final switch(cpInfo.tag.val) with(CONSTANT) {
      case Class: {
        auto info = cast(CONSTANT_Class_info*)cpInfo.ptr;
        dbg("    name_index: ", info.name_index.unpack!ushort);
        cp ~= info;
        cf.constant_pool.size = cf.constant_pool.size + CONSTANT_Class_info.sizeof;
        break;
      }
      case Fieldref: {
        auto info = cast(CONSTANT_Fieldref_info*)cpInfo.ptr;
        dbg("    class_index:         ", info.class_index.unpack!ushort);
        dbg("    name_and_type_index: ", info.name_and_type_index.unpack!ushort);
        cp ~= info;
        cf.constant_pool.size = cf.constant_pool.size + CONSTANT_Fieldref_info.sizeof;
        break;
      }
      case Methodref: {
        auto info = cast(CONSTANT_Methodref_info*)cpInfo.ptr;
        dbg("    class_index:         ", info.class_index.unpack!ushort);
        dbg("    name_and_type_index: ", info.name_and_type_index.unpack!ushort);
        cp ~= info;
        cf.constant_pool.size = cf.constant_pool.size + CONSTANT_Methodref_info.sizeof;
        break;
      }
      case InterfaceMethodref: NIY;
      case String: {
        auto info = cast(CONSTANT_String_info*)cpInfo.ptr;
        dbg("    string_index: ", info.string_index.unpack!ushort);
        cp ~= info;
        cf.constant_pool.size = cf.constant_pool.size + CONSTANT_String_info.sizeof;
        break;
      }
      case Integer: NIY;
      case Float: NIY;
      case Long: NIY;
      case Double: NIY;
      case NameAndType: {
        auto info = cast(CONSTANT_NameAndType_info*)cpInfo.ptr;
        dbg("    name_index:        ", info.name_index.unpack!ushort);
        dbg("    descriptor_index:  ", info.descriptor_index.unpack!ushort);
        cp ~= info;
        cf.constant_pool.size = cf.constant_pool.size + CONSTANT_NameAndType_info.sizeof;
        break;
      }
      case Utf8: {
        auto info = cast(CONSTANT_Utf8_info*)cpInfo.ptr;
        auto len = info.length.unpack!ushort;
        auto buf = info.bytes.ptr[0 .. len];
        dbg("    length:  ", len);
        dbg("    bytes:   ", buf);
        dbg(`    content: "`, cast(char[])buf, `"`);
        cp ~= info;
        cf.constant_pool.size = cf.constant_pool.size + CONSTANT_Utf8_info.sizeof + len;
        break;
      }
      case MethodHandle: NIY;
      case MethodType: NIY;
      case InvokeDynamic: NIY;
    }
  }

  // interfaces

  // fields

  // methods

  // attributes

  return cf;
}
