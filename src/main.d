module djvm.main;

import std;
import djvm.loader;
import djvm.exec;

void main() {
  auto res = loadClassFile("test/Hello.class");
  execMain(res.cf, res.cp, res.meths);
}
