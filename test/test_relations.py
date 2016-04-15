# Stefan Burckhardt

import unittest

import psycopg2
import psycopg2.extras
import decimal
from time import sleep

from utils import DbTestBase

class TestRelations(unittest.TestCase, DbTestBase):

    @classmethod
    def tearDownClass(cls):
        cls.conn.rollback()

    @classmethod
    def setUpClass(cls):
        cls.conn = psycopg2.connect("service=pg_qgep")


    def test_relations(self):
        # create cover element
        row = {
                'identifier': 'CO123',
                'level': decimal.Decimal('50.000')
        }

        obj_id = self.insert_check('vw_cover', row)
        print "obj_id =", obj_id
        row = {
                'identifier': 'CO456',
                'level': decimal.Decimal('60.656')
        }

        # create 2nd cover element
        obj_id2 = self.insert_check('vw_cover', row)
        print "obj_id2 =", obj_id2
        
        row = self.select('od_structure_part', obj_id)

        cur = self.cursor()

        # count objects
        cur.execute("SELECT COUNT(*) FROM qgep.od_structure_part WHERE obj_id IN ('00000000CO000000', '00000000CO000001')")
        amount_structure_part = cur.fetchone()
        cur.execute("SELECT COUNT(*) FROM qgep.od_cover WHERE obj_id IN ('00000000CO000000', '00000000CO000001')")
        amount_cover = cur.fetchone()
        
        print "Count after creation"
        print "amount_structure_part = ", amount_structure_part
        print "amount_cover =", amount_cover
        
        # delete od_structure_part with obj_id
        cur.execute("DELETE FROM qgep.od_structure_part WHERE obj_id='{obj_id}'".format(obj_id=obj_id))
        
        # count amount of structure part elements and cover elements - should be one each
        # obj_id are 00000000CO000000 or 00000000CO000001
        cur.execute("SELECT COUNT(*) FROM qgep.od_structure_part WHERE obj_id IN ('00000000CO000000', '00000000CO000001')")
        amount_structure_part = cur.fetchone()
        # amount_structure_part = cur.execute("SELECT COUNT(*) FROM qgep.od_structure_part WHERE identifier IN ('CO123', 'CO456')")

        cur.execute("SELECT COUNT(*) FROM qgep.od_cover WHERE obj_id IN ('00000000CO000000', '00000000CO000001')")
        amount_cover = cur.fetchone()
        
        
        amount_cover_str = str(amount_cover[0])
        amount_structure_part_str = str(amount_structure_part[0])
        print 'amount_structure is type string = ',isinstance(amount_structure_part_str, str)
        print 'amount_structure is type string = ',isinstance(amount_cover_str, str)
        
        print 'comparison is', (amount_structure_part_str is amount_cover_str)
        print 'comparison ==', (amount_structure_part_str == amount_cover_str)
        
        def num(s):
            try:
                return int(s)
            except ValueError:
                return float(s)
        
        amount_cover_int = num(amount_cover_str)
        amount_structure_part_int = num(amount_structure_part_str)
        
        print 'int comparison is', (amount_structure_part_int is amount_cover_int)
        print 'int comparison ==', (amount_structure_part_int == amount_cover_int)
        
        # print "amount_cover[0] =", amount_cover[0]
        print "Count after deleting cover obj_id = 00000000CO000000"
        print "amount_structure_part_str = ", amount_structure_part_str
        print "amount_cover_str =", amount_cover_str
        print "amount_structure_part_str = ", amount_structure_part_int
        print "amount_cover_str =", amount_cover_int
        
        assert amount_structure_part_int == amount_cover_int, "Relation test for structure_part - cover failed"
        # assert amount_structure_part_str is amount_cover_str, "Relation test for structure_part - cover failed"
        # assert amount_structure_part != amount_cover, "Relation test for structure_part - cover failed"

        

if __name__ == '__main__':
    unittest.main()