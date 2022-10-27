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

auto loadConstantPools(Dyns!ClassFile cf) {
  void*[] cp;
  auto cpNum = cf.constant_pool_count.val.unpack!ushort - 1;
  dbg("\nconstant pools count: ", cpNum);
  foreach(i; 0 .. cpNum) {
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
        dbg(`    content: "`, cast(string)buf, `"`);
        cp ~= info;
        cf.constant_pool.size = cf.constant_pool.size + CONSTANT_Utf8_info.sizeof + len;
        break;
      }
      case MethodHandle: NIY;
      case MethodType: NIY;
      case InvokeDynamic: NIY;
    }
  }

  return cast(cp_info*[])cp;
}

auto loadInterfaces(Dyns!ClassFile cf) {
  cf.interfaces.size = 2 * cf.interfaces_count.val.unpack!ushort;
  dbg("\ninterfaces buffer size: ", cf.interfaces.size);
}

auto loadFields(Dyns!ClassFile cf) {
  auto fieldsNum = cf.fields_count.val.unpack!ushort;
  dbg("\nfields count: ", fieldsNum);
  foreach(i; 0 .. fieldsNum) {
    auto fieldInfo = new Dyns!field_info(cf.fields.ptr + cf.fields.size);
    dbg("  field [", i, "]: ");

    foreach(j; 0 .. fieldInfo.attributes_count.val.unpack!ushort) {
      auto attrInfo = new Dyns!attribute_info(
        fieldInfo.attributes.ptr + fieldInfo.attributes.size);
      attrInfo.info.size = attrInfo.attribute_length.val.unpack!uint;
      fieldInfo.attributes.size = fieldInfo.attributes.size + attrInfo.size;
    }

    cf.fields.size = cf.fields.size + fieldInfo.size;
  }
}

auto loadMethods(Dyns!ClassFile cf, cp_info*[] cp) {
  auto methodsNum = cf.methods_count.val.unpack!ushort;
  dbg("\nmethods count: ", methodsNum);
  foreach(i; 0 .. methodsNum) {
    auto methodInfo = new Dyns!method_info(cf.methods.ptr + cf.methods.size);
    methodInfo.attributes.size = 0; //

    ACC[] flags;
    auto flagsVal = methodInfo.access_flags.val.unpack!ushort;
    foreach(flag; EnumMembers!ACC)
      if(flagsVal & flag) flags ~= flag;
    dbg("\n  method [", i, "]: ", flags);

    auto nameIdx = methodInfo.name_index.val.unpack!ushort;
    auto name = new Dyns!CONSTANT_Utf8_info(cp[nameIdx - 1]);
    name.bytes.size = name.length.val.unpack!ushort;
    dbg(`    name: "`, cast(string)name.bytes.val, `"`);

    auto descIdx = methodInfo.descriptor_index.val.unpack!ushort;
    auto desc = new Dyns!CONSTANT_Utf8_info(cp[descIdx - 1]);
    desc.bytes.size = desc.length.val.unpack!ushort;
    dbg(`    desc: "`, cast(string)desc.bytes.val, `"`);

    auto attrsNum = methodInfo.attributes_count.val.unpack!ushort;
    dbg("    attributes count: ", attrsNum);
    foreach(j; 0 .. attrsNum) {
      auto attrInfo = new Dyns!attribute_info(
        methodInfo.attributes.ptr + methodInfo.attributes.size);
      attrInfo.info.size = attrInfo.attribute_length.val.unpack!uint;
      dbg("      attr [", j, "]:");

      auto attrNameIdx = attrInfo.attribute_name_index.val.unpack!ushort;
      auto attrName = new Dyns!CONSTANT_Utf8_info(cp[attrNameIdx - 1]);
      attrName.bytes.size = attrName.length.val.unpack!ushort;
      dbg(`        name: "`, cast(string)attrName.bytes.val, `"`);

      methodInfo.attributes.size = methodInfo.attributes.size + attrInfo.size;
    }

    cf.methods.size = cf.methods.size + methodInfo.size;
  }
}

auto loadAttributes(Dyns!ClassFile cf, cp_info*[] cp) {
  auto attrsNum = cf.attributes_count.val.unpack!ushort;
  dbg("\nattrs count: ", attrsNum);
  foreach(i; 0 .. attrsNum) {
    auto attrInfo = new Dyns!attribute_info(cf.attributes.ptr + cf.attributes.size);
    attrInfo.info.size = attrInfo.attribute_length.val.unpack!uint;
    dbg("  attr [", i, "]:");

    auto attrNameIdx = attrInfo.attribute_name_index.val.unpack!ushort;
    auto attrName = new Dyns!CONSTANT_Utf8_info(cp[attrNameIdx - 1]);
    attrName.bytes.size = attrName.length.val.unpack!ushort;
    dbg(`    name: "`, cast(string)attrName.bytes.val, `"`);

    cf.attributes.size = cf.attributes.size + attrInfo.size;
  }
}

auto loadClassFile(string path) {
  auto f = File(path);
  scope(exit) f.close;
  auto fbuf = f.rawRead(new ubyte[f.size]);
  auto cf = new Dyns!ClassFile(fbuf.ptr);
  dbg("\nloading file: ", path);

  auto cp = loadConstantPools(cf);
  loadInterfaces(cf);
  loadFields(cf);
  loadMethods(cf, cp);
  loadAttributes(cf, cp);

  return cf;
}
