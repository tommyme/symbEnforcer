from pprint import pprint
"""let mapper:[Int: Array] = [43:[ord(","), ord("<")],
                           47:[ord("."), ord(">")],
                           44:[ord("/"), ord("?")],]"""
source = """!118
@219
#320
$421
%523
^622
&726
*828
(925
)029
~`50
{[33
}]30
|\\42
:;41
"'39
_-27
+=24
<,43
>.47
?/44
qQ12
wW13
eE14
rR15
tT17
yY16
uU32
iI34
oO31
pP35
aA0
sS1
dD2
fF3
gG5
hH4
jJ38
kK40
lL37
zZ6
xX7
cC8
vV9
bB11
nN45
mM46""".split("\n")
ddict  = {}
for i in source:
    shifted, origin, keycode = i[0], i[1], int(i[2:])
    print(origin, shifted, keycode)
    ddict[keycode] = [ord(origin), ord(shifted)]

pprint(ddict, sort_dicts=False)



