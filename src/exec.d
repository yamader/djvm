module djvm.exec;

import std;
import djvm.libs;
import djvm.loader;
import djvm.classfile;
import djvm.instruction;

auto exec(Dyns!Code_attribute attr, cp_info*[] cp) {
  auto codeLen = attr.code_length.val.unpack!uint;
  auto code = attr.code.val;
  dbg("  code length: ", codeLen);

  for(size_t i=0; i<codeLen; i++) {
    switch(code[i]) with(Opcode) {
      case ldc: {
        dbg("    ldc ", code[i+1]);
        i++;
        continue;
      }
      case getstatic: {
        dbg("    getstatic ", code[i+1], " ", code[i+2]);
        i += 2;
        continue;
      }
      case invokevirtual: {
        dbg("    invokevirtual ", code[i+1], " ", code[i+2]);
        i += 2;
        continue;
      }
      case return_: {
        dbg("    return");
        continue;
      }
      default: NIY;
    }
  }
}

auto execMain(Dyns!ClassFile cf, cp_info*[] cp, Dyns!method_info[] meths) {
  dbg("\nsearching main method");
  auto mainIdx = meths.countUntil!((info) {
    auto nameIdx = info.name_index.val.unpack!ushort;
    auto name = loadUtf8Constant(cp[nameIdx - 1]).str;
    return name == "main";
  });
  if(mainIdx < 0) throw new Exception("cannot find main");
  dbg("  found: [", mainIdx, "]");

  auto attrsNum = meths[mainIdx].attributes_count.val.unpack!ushort;
  auto attrs = loadAttrs(meths[mainIdx].attributes.ptr, attrsNum);
  attrs.each!((info) {
    auto attrNameIdx = info.attribute_name_index.val.unpack!ushort;
    auto attrName = loadUtf8Constant(cp[attrNameIdx - 1]).str;
    switch(attrName) {
      case "Code": {
        auto code = loadCodeAttr(info);
        exec(code, cp);
        break;
      }
      default: NIY;
    }
  });
}
