#include <leveldb/db.h>
#include <fstream>
#include <iomanip>
void hex(std::ostream& o,leveldb::Slice s){for(unsigned char c: s.ToString())o<<std::hex<<std::setw(2)<<std::setfill('0')<<(unsigned)c;}
int main(int argc,char**argv){leveldb::DB*d=nullptr;leveldb::Options o;auto st=leveldb::DB::Open(o,argv[1],&d);if(!st.ok())return 1;auto it=d->NewIterator(leveldb::ReadOptions());std::ofstream f(argv[2]);for(it->SeekToFirst();it->Valid();it->Next()){hex(f,it->key());f<<' ';hex(f,it->value());f<<'\n';}bool ok=it->status().ok();delete it;delete d;return ok?0:2;}
