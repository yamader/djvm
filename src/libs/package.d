module djvm.libs;

public import djvm.libs.dyns;

//

import std;
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

auto str(Dyns!CONSTANT_Utf8_info info) => cast(string)info.bytes.val;
