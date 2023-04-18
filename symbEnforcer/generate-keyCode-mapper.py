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
?/44""".split("\n")
ddict  = {}
for i in source:
    shifted, origin, keycode = i[0], i[1], int(i[2:])
    print(origin, shifted, keycode)
    ddict[keycode] = [ord(origin), ord(shifted)]

print(ddict)


