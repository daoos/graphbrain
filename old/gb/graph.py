# -*- coding: utf-8 -*-


from datetime import datetime

from dbobj import DbObj
from node import Node
import urlparser


class Graph(DbObj):
    def __init__(self):
        DbObj.__init__(self)
        self.collection = 'nodes'

    def create(self, name, owner):
        self.d['label'] = name
        self.d['type'] = 'graph'
        self.d['graph'] = 'graphs'
        self.d['creation_ts'] = datetime.now()
        self.d['owner'] = owner.d['_id']

        self._insert()

        return self

    def set_root(self, root):
        self._set_field('root', root.d['_id'])

    def get_by_owner_and_name(self, owner, name):
        self.d = self.db.nodes.find_one({'owner': owner.d['_id'], 'label': name})
        return self

    def add_link(self, orig, targ, rel, rel_raw, sentence='', directed=1):
        self.db.nodes.update({'_id': orig.d['_id']}, {'$addToSet': {'targs.%s' % targ.d['_id']: {'relation': rel, 'relation_raw': rel_raw, 'sentence': sentence, 'directed': directed}}})
        self.db.nodes.update({'_id': targ.d['_id']}, {'$addToSet': {'origs': orig.d['_id']}})

    def del_link(self, orig_id, targ_id, rel):
        orig = Node().get_by_id(orig_id)
        targ = Node().get_by_id(targ_id)

        targs = orig.d['targs'][str(targ.d['_id'])]
        todel = None
        for t in targs:
            if t['relation'] == rel:
                todel = t
                targs.remove(todel)
                break

        if len(targs) == 0:
            del orig.d['targs'][str(targ.d['_id'])]
                
        if todel is not None:
            orig._update_field('targs')

        if len(targs) == 0:
            targ.d['origs'].remove(orig.d['_id'])
            targ._update_field('origs')

    def add_rel(self, rel, orig_text='', targ_text='', orig_id='none', targ_id='none'):
        orig = Node()
        targ = Node()
        
        if orig_id != 'none':
            orig.get_by_id(orig_id)
        elif orig_text != '':
            orig.get_by_label(orig_text, self.d['_id'])
            if orig.d is None:
                ntype = urlparser.nodetype(orig_text)
                orig.create(orig_text, self, ntype)
        else:
            return False
        
        if targ_id != 'none':
            targ.get_by_id(targ_id)
        elif targ_text != '':
            targ.get_by_label(targ_text, self.d['_id'])
            if targ.d is None:
                ntype = urlparser.nodetype(targ_text)
                targ.create(targ_text, self, ntype)
        else:
            return False

        # create new link between nodes
        self.add_link(orig, targ, rel, rel)

        return True
    
    def add_rel_from_parser(self, r):
        orig = Node().get_by_label(r['orig'], self.d['_id'])
        targ = Node().get_by_label(r['targ'], self.d['_id'])

        # one of the nodes has to exist in the graph
        if (orig.d is None) and (targ.d is None):
            return False

        # create one of the nodes if it does not exist
        if orig.d is None:
            orig.create(r['orig'], self, r['orig_type'])
        elif targ.d is None:
            targ.create(r['targ'], self, r['targ_type'])

        # create new link between nodes
        self.add_link(orig, targ, r['rel'], r['rel_raw'], r['sentence'])

        return True