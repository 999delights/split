import importlib.util,json,tempfile,unittest
from pathlib import Path
spec=importlib.util.spec_from_file_location('legacy',Path(__file__).resolve().parents[1]/'scripts/import_legacy.py');legacy=importlib.util.module_from_spec(spec);spec.loader.exec_module(legacy)
class ImportTests(unittest.TestCase):
 def test_exact_import_preserves_mapping_and_refuses_overwrite(self):
  with tempfile.TemporaryDirectory() as folder:
   root=Path(folder);src=root/'export.json';target=root/'import.db'
   records={'users':{'id':'u','nickname':'Test','groups':['g']},'groups':{'id':'g','name':'Trip','users':['u'],'createdUsers':{'v':'Guest'},'paymentsId':{'p':'u'},'date':{'seconds':0},'profilePic':'group7','color':'Cgroup13'},'payments':{'id':'p','group':'g','name':'Meal','by':'v','price':'10.01','split':{'u':'5','v':'5.01'},'date':{'seconds':0}}}
   src.write_text(json.dumps({'documents':[{'path':'projects/test/documents/'+k+'/'+v['id'],'fields':v} for k,v in records.items()]}))
   report=legacy.run(src,target);self.assertEqual(report[0]['my_balance_minor'],-500)
   with self.assertRaises(ValueError):legacy.run(src,target)
   records['groups']['paymentsId']['missing']='u'
   src.write_text(json.dumps({'documents':[{'path':'projects/test/documents/'+k+'/'+v['id'],'fields':v} for k,v in records.items()]}))
   with self.assertRaises(AssertionError):legacy.run(src,root/'bad.db')
   self.assertFalse((root/'bad.db').exists())
