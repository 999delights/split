"""Product-owned email palette and default copy. No external assets or secrets."""
BRAND = {'product': 'split',
 'name': 'Split Paper',
 'wordmark': 'Split Paper.',
 'tagline': 'Split expenses with any group.',
 'layout': 'paper',
 'background': '#edf3ee',
 'surface': '#ffffff',
 'ink': '#24322a',
 'muted': '#5c6d62',
 'line': '#d8e3da',
 'accent': '#2bc653',
 'button_ink': '#092a12',
 'radius': 10,
 'eyebrow': 'GOOD TIMES. CLEAR BALANCES.',
 'footer': 'Spend together. Settle clearly.',
 'templates': {'welcome': ('Less calculating. More time together.',
                           'Hi {{display_name}},\n'
                           '\n'
                           'Welcome to Split Paper. Create a group for a trip, a shared home or a night out, '
                           'add an expense and decide how to split it.\n'
                           '\n'
                           'See what you spent, what you owe and what you’re owed, all in one place.'),
               'email-verification': ('Confirm your email for Split Paper',
                                      'Hi {{display_name}},\n'
                                      '\n'
                                      'Confirm this address to enable email sign-in for your Split Paper '
                                      'account. Your groups, shared expenses and balances stay together in '
                                      'the same place.\n'
                                      '\n'
                                      'A small step now, fewer things to keep track of later.'),
               'password-reset': ('A new password. The same shared expenses.',
                                  'Hi {{display_name}},\n'
                                  '\n'
                                  'You requested a password reset for Split Paper. Use the secure link below '
                                  'to choose a new password.\n'
                                  '\n'
                                  'Your groups, expenses and balances will not be changed.'),
               'password-changed': ('Your Split Paper password is now updated',
                                    'Hi {{display_name}},\n'
                                    '\n'
                                    'Your password has been changed. Existing app sign-in sessions have been '
                                    'revoked, so sign in again on your devices.\n'
                                    '\n'
                                    'Everything you have recorded in your groups stays in place.'),
               'identity-linked': ('{{provider}} is linked to your Split Paper account',
                                   'Hi {{display_name}},\n'
                                   '\n'
                                   'You can now use {{provider}} to sign in to your existing Split Paper '
                                   'account. You will see the same groups, expenses and balances.\n'
                                   '\n'
                                   'Another sign-in method, with nothing to split between accounts.'),
               'security-alert': ('Review access to your Split Paper account',
                                  'Hi {{display_name}},\n'
                                  '\n'
                                  'Open Split Paper to review your sign-in methods and active sessions after '
                                  'an account security update.\n'
                                  '\n'
                                  'Your groups and shared expenses remain linked to your account.')}}
