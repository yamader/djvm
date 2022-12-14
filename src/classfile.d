module djvm.classfile;

import std;

// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-4.html

alias u1 = ubyte;
alias u2 = ubyte[2];
alias u4 = ubyte[4];

// 4.1. ClassFile

struct ClassFile {
 align(1):
  u4 magic;
  u2 minor_version;
  u2 major_version;
  u2 constant_pool_count;
  cp_info[0] constant_pool; // [constant_pool_count-1]
  u2 access_flags;
  u2 this_class;
  u2 super_class;
  u2 interfaces_count;
  u2[0] interfaces; // [interfaces_count]
  u2 fields_count;
  field_info[0] fields; // [fields_count]
  u2 methods_count;
  method_info[0] methods; // [methods_count]
  u2 attributes_count;
  attribute_info[0] attributes; // [attributes_count]
}

// 4.4. Constant Pool

alias CONSTANTS = AliasSeq!(
  CONSTANT_Class_info, CONSTANT_Fieldref_info, CONSTANT_Methodref_info, CONSTANT_InterfaceMethodref_info,
  CONSTANT_String_info, CONSTANT_Integer_info, CONSTANT_Float_info, CONSTANT_Long_info, CONSTANT_Double_info,
  CONSTANT_NameAndType_info, CONSTANT_Utf8_info, CONSTANT_MethodHandle_info, CONSTANT_MethodType_info, CONSTANT_InvokeDynamic_info);

// Constant pool tags
enum CONSTANT: ubyte {
  Class = 7,
  Fieldref = 9,
  Methodref = 10,
  InterfaceMethodref = 11,
  String = 8,
  Integer = 3,
  Float = 4,
  Long = 5,
  Double = 6,
  NameAndType = 12,
  Utf8 = 1,
  MethodHandle = 15,
  MethodType = 16,
  InvokeDynamic = 18,
}

struct cp_info {
 align(1):
  u1 tag;
  u1[0] info;
}

struct CONSTANT_Class_info {
 align(1):
  u1 tag;
  u2 name_index;
}
struct CONSTANT_Fieldref_info {
 align(1):
  u1 tag;
  u2 class_index;
  u2 name_and_type_index;
}
alias CONSTANT_Methodref_info = CONSTANT_Fieldref_info;
alias CONSTANT_InterfaceMethodref_info = CONSTANT_Fieldref_info;
struct CONSTANT_String_info {
 align(1):
  u1 tag;
  u2 string_index;
}
struct CONSTANT_Integer_info {
 align(1):
  u1 tag;
  u4 bytes;
}
alias CONSTANT_Float_info = CONSTANT_Integer_info;
struct CONSTANT_Long_info {
 align(1):
  u1 tag;
  u4 high_bytes;
  u4 low_bytes;
}
alias CONSTANT_Double_info = CONSTANT_Long_info;
struct CONSTANT_NameAndType_info {
 align(1):
  u1 tag;
  u2 name_index;
  u2 descriptor_index;
}
struct CONSTANT_Utf8_info {
 align(1):
  u1 tag;
  u2 length;
  u1[0] bytes;
}
struct CONSTANT_MethodHandle_info {
 align(1):
  u1 tag;
  u1 reference_kind;
  u2 reference_index;
}
struct CONSTANT_MethodType_info {
 align(1):
  u1 tag;
  u2 descriptor_index;
}
struct CONSTANT_InvokeDynamic_info {
 align(1):
  u1 tag;
  u2 bootstrap_method_attr_index;
  u2 name_and_type_index;
}

// 4.5. Fields

struct field_info {
 align(1):
  u2 access_flags;
  u2 name_index;
  u2 descriptor_index;
  u2 attributes_count;
  attribute_info[0] attributes; // [attributes_count]
}

// 4.6. Methods

// Access Flags
enum ACC: ushort {
  Public = 0x0001,
  Private = 0x0002,
  Protected = 0x0004,
  Static = 0x0008,
  Final = 0x0010,
  Synchronized = 0x0020,
  Bridge = 0x0040,
  VarArgs = 0x0080,
  Native = 0x100,
  Abstract = 0x0400,
  Strict = 0x0800,
  Synthetic = 0x1000,
}

struct method_info {
 align(1):
  u2 access_flags;
  u2 name_index;
  u2 descriptor_index;
  u2 attributes_count;
  attribute_info[0] attributes; // [attributes_count]
}

// 4.7. Attributes

struct attribute_info {
 align(1):
  u2 attribute_name_index;
  u4 attribute_length;
  u1[0] info; // [attribute_length]
}

struct ETab {
 align(1):
  u2 start_pc;
  u2 end_pc;
  u2 handler_pc;
  u2 catch_type;
}

struct Code_attribute {
 align(1):
  u2 attribute_name_index;
  u4 attribute_length;
  u2 max_stack;
  u2 max_locals;
  u4 code_length;
  u1[0] code; // [code_length]
  u2 exception_table_length;
  ETab[0] exception_table; // [exception_table]
  u2 attributes_count;
  attribute_info[0] attributes; // [attributes_count]
}
