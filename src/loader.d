module djvm.loader;

import std;
import djvm.libs;
import djvm.classfile;

// Constants

auto loadUtf8Constant(cp_info* c) {
  auto res = new Dyns!CONSTANT_Utf8_info(c);
  res.bytes.size = res.length.val.unpack!ushort;
  return res;
}

// Attributes

auto loadAttrInfo(const void* attr) {
  auto res = new Dyns!attribute_info(attr);
  res.info.size = res.attribute_length.val.unpack!uint;
  return res;
}

auto loadAttrs(const void* attrs, size_t n) {
  Dyns!attribute_info[] res;
  size_t offs;
  foreach(i; 0 .. n) {
    auto attr = loadAttrInfo(attrs + offs);
    res ~= attr;
    offs += attr.size;
  }
  return res;
}

auto loadCodeAttr(Dyns!attribute_info attr) {
  auto res = new Dyns!Code_attribute(attr.ptr);
  res.code.size = res.code_length.val.unpack!uint;
  res.exception_table.size = ETab.sizeof * res.exception_table_length.val.unpack!ushort;
  auto attrs = loadAttrs(res.attributes.ptr, res.attributes_count.val.unpack!ushort);
  res.attributes.size = attrs.map!`a.size`.sum;
  if(res.size != attr.size) throw new Exception("bad code attribute");
  return res;
}

// ClassFile

auto cfLoadConstantPools(Dyns!ClassFile cf) {
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

auto cfLoadInterfaces(Dyns!ClassFile cf) {
  cf.interfaces.size = 2 * cf.interfaces_count.val.unpack!ushort;
  dbg("\ninterfaces buffer size: ", cf.interfaces.size);
}

auto cfLoadFields(Dyns!ClassFile cf) {
  auto fieldsNum = cf.fields_count.val.unpack!ushort;
  dbg("\nfields count: ", fieldsNum);
  foreach(i; 0 .. fieldsNum) {
    auto fieldInfo = new Dyns!field_info(cf.fields.ptr + cf.fields.size);
    dbg("  field [", i, "]: ");

    auto attrs = loadAttrs(fieldInfo.attributes.ptr, fieldInfo.attributes_count.val.unpack!ushort);
    fieldInfo.attributes.size = attrs.map!`a.size`.sum;

    cf.fields.size = cf.fields.size + fieldInfo.size;
  }
}

auto cfLoadMethods(Dyns!ClassFile cf, cp_info*[] cp) {
  Dyns!method_info[] res;
  auto methodsNum = cf.methods_count.val.unpack!ushort;
  dbg("\nmethods count: ", methodsNum);
  foreach(i; 0 .. methodsNum) {
    auto methodInfo = new Dyns!method_info(cf.methods.ptr + cf.methods.size);

    ACC[] flags;
    auto flagsVal = methodInfo.access_flags.val.unpack!ushort;
    foreach(flag; EnumMembers!ACC)
      if(flagsVal & flag) flags ~= flag;
    dbg("\n  method [", i, "]: ", flags);

    auto nameIdx = methodInfo.name_index.val.unpack!ushort;
    auto name = loadUtf8Constant(cp[nameIdx - 1]).str;
    dbg(`    name: "`, name, `"`);

    auto descIdx = methodInfo.descriptor_index.val.unpack!ushort;
    auto desc = loadUtf8Constant(cp[descIdx - 1]).str;
    dbg(`    desc: "`, desc, `"`);

    auto attrsNum = methodInfo.attributes_count.val.unpack!ushort;
    dbg("    attributes count: ", attrsNum);
    foreach(j; 0 .. attrsNum) {
      auto attrInfo = loadAttrInfo(methodInfo.attributes.ptr + methodInfo.attributes.size);
      dbg("      attr [", j, "]:");

      auto attrNameIdx = attrInfo.attribute_name_index.val.unpack!ushort;
      auto attrName = loadUtf8Constant(cp[attrNameIdx - 1]).str;
      dbg(`        name: "`, attrName, `"`);

      methodInfo.attributes.size = methodInfo.attributes.size + attrInfo.size;
    }
    res ~= methodInfo;
    cf.methods.size = cf.methods.size + methodInfo.size;
  }
  return res;
}

auto cfLoadAttributes(Dyns!ClassFile cf, cp_info*[] cp) {
  auto attrsNum = cf.attributes_count.val.unpack!ushort;
  dbg("\nattrs count: ", attrsNum);
  foreach(i; 0 .. attrsNum) {
    auto attrInfo = new Dyns!attribute_info(cf.attributes.ptr + cf.attributes.size);
    attrInfo.info.size = attrInfo.attribute_length.val.unpack!uint;
    dbg("  attr [", i, "]:");

    auto attrNameIdx = attrInfo.attribute_name_index.val.unpack!ushort;
    auto attrName = loadUtf8Constant(cp[attrNameIdx - 1]).str;
    dbg(`    name: "`, attrName, `"`);

    // ref: Table 4.7-C

    cf.attributes.size = cf.attributes.size + attrInfo.size;
  }
}

auto loadClassFile(string path) {
  auto f = File(path);
  scope(exit) f.close;
  auto fbuf = f.rawRead(new ubyte[f.size]);
  auto cf = new Dyns!ClassFile(fbuf.ptr);
  dbg("\nloading file: ", path);

  auto cp = cfLoadConstantPools(cf);
  cfLoadInterfaces(cf);
  cfLoadFields(cf);
  auto meths = cfLoadMethods(cf, cp);
  cfLoadAttributes(cf, cp);
  dbg("\nloading classfile done");

  return tuple!("cf", "cp", "meths")(cf, cp, meths);
}
