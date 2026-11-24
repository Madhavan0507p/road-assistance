with open(r'web/admin/mechanic-approval.jsp', 'r', encoding='utf-8') as f:
    text = f.read()

import re
modals = re.findall(r'<div[^>]+id=[\'"]([^\'"]*modal[^\'"]*)[\'"]', text, re.IGNORECASE)
print('Modals found:', modals)

# Also find actions column buttons
actions_idx = text.find('ACTIONS')
if actions_idx != -1:
    print('--- Actions column search ---')
    print(text[actions_idx:actions_idx+1500])
