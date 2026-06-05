import re, sys

proj, widget_profile = sys.argv[1], sys.argv[2]

with open(proj) as f:
    content = f.read()

def patch(m):
    block = m.group(0)
    if ('com.texapp.atensia.AtensiaWidget' in block
            and 'PROVISIONING_PROFILE_SPECIFIER' not in block):
        block = block.replace(
            'PRODUCT_BUNDLE_IDENTIFIER = com.texapp.atensia.AtensiaWidget;',
            'PRODUCT_BUNDLE_IDENTIFIER = com.texapp.atensia.AtensiaWidget;\n'
            '\t\t\t\tPROVISIONING_PROFILE_SPECIFIER = "' + widget_profile + '";'
        )
    return block

patched = re.sub(r'buildSettings = \{[^}]+\}', patch, content, flags=re.DOTALL)

with open(proj, 'w') as f:
    f.write(patched)

print(f'Widget target patched with profile: {widget_profile}')
