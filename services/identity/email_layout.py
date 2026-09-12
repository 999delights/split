"""Table-based email HTML with inline fallbacks; no remote resources or scripts."""
from html import escape


def render_html(brand, *, title, body, preheader, label, action_url, action_label,
                security_note, environment):
    b = brand
    esc = lambda value: escape(str(value), quote=True)
    p = {key: esc(value) for key, value in b.items() if key != 'templates'}
    paragraphs = ''.join(
        '<p style="margin:0 0 20px;font-size:16px;line-height:26px;word-break:break-word;overflow-wrap:anywhere;">'
        + esc(part).replace('\n', '<br>') + '</p>' for part in body.split('\n\n')
    )
    wordmark = p['wordmark']
    mark_style = 'font-family:Arial,Helvetica,sans-serif;font-weight:900;'
    border = 'border:1px solid ' + p['line'] + ';'
    if b['layout'] == 'console':
        mark_style += 'font-size:42px;letter-spacing:6px;'
        ornament = ('<tr><td style="padding:0 36px 26px;"><table role="presentation" width="100%" '
                    'cellpadding="0" cellspacing="0"><tr>' + ''.join(
                        '<td width="33%" style="height:4px;background:' + color + ';font-size:0;line-height:0;">&nbsp;</td>'
                        for color in ['#fafafa', '#9e9ea8', '#494950']) + '</tr></table></td></tr>')
    elif b['layout'] == 'cinema':
        mark_style += 'font-family:Arial Black,Arial,Helvetica,sans-serif;font-size:52px;letter-spacing:-3px;'
        ornament = ('<tr><td align="center" style="padding:0 36px 28px;"><table role="presentation" '
                    'cellpadding="0" cellspacing="0"><tr><td width="56" height="56" align="center" '
                    'bgcolor="' + p['accent'] + '" style="border-radius:50%;color:' + p['button_ink'] + ';font-size:25px;">'
                    '<span aria-hidden="true">&#9654;</span></td><td style="padding-left:14px;font-size:11px;'
                    'letter-spacing:2px;color:' + p['muted'] + ';">YOUR MEDIA<br><span style="line-height:24px;">YOUR SPACE</span>'
                    '</td></tr></table></td></tr>')
    elif b['layout'] == 'matchday':
        mark_style += 'font-size:44px;letter-spacing:4px;font-style:italic;'
        ornament = ('<tr><td style="padding:0 36px 26px;"><table role="presentation" width="100%" '
                    'cellpadding="0" cellspacing="0"><tr><td><div style="height:1px;background:' + p['line'] + ';font-size:0;line-height:0;">&nbsp;</div></td>'
                    '<td width="44" align="center" style="color:' + p['accent'] + ';font-size:24px;">&#9675;</td>'
                    '<td><div style="height:1px;background:' + p['line'] + ';font-size:0;line-height:0;">&nbsp;</div></td></tr></table></td></tr>')
    else:
        mark_style += 'font-size:38px;letter-spacing:-1.5px;'
        ornament = ('<tr><td style="padding:0 36px 26px;"><div style="border-top:2px dashed '
                    + p['line'] + ';height:1px;font-size:0;">&nbsp;</div></td></tr>')
    action = ''
    if action_url:
        action = ('<tr><td class="pad" style="padding:4px 36px 28px;"><table role="presentation" '
                  'cellpadding="0" cellspacing="0"><tr><td bgcolor="' + p['accent'] + '" '
                  'style="border-radius:' + ('4' if b['layout'] == 'console' else '12') + 'px;">'
                  '<a href="' + esc(action_url) + '" style="display:inline-block;padding:17px 24px;'
                  'border:1px solid ' + p['accent'] + ';border-radius:inherit;font-family:Arial,Helvetica,sans-serif;'
                  'font-size:16px;font-weight:bold;text-decoration:none;color:' + p['button_ink'] + ';">'
                  + esc(action_label) + '</a></td></tr></table></td></tr>')
    env = '' if environment == 'production' else ('<span style="font-size:10px;letter-spacing:1px;">'
                                                  + esc(environment.upper()) + ' &nbsp; / &nbsp; </span>')
    return f'''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="x-apple-disable-message-reformatting"><meta name="format-detection" content="telephone=no,date=no,address=no,email=no">
<title>{esc(title)}</title><style>
body,table,td,a {{-webkit-text-size-adjust:100%;-ms-text-size-adjust:100%;}}
table,td {{mso-table-lspace:0pt;mso-table-rspace:0pt;}}
body {{margin:0!important;padding:0!important;}}
a[x-apple-data-detectors] {{color:inherit!important;text-decoration:none!important;}}
@media screen and (max-width:620px) {{.outer {{padding:18px 10px!important;}}.pad {{padding-left:24px!important;padding-right:24px!important;}}.heading {{font-size:28px!important;line-height:35px!important;}}}}
</style></head>
<body bgcolor="{p['background']}" style="background:{p['background']};margin:0;padding:0;font-family:Arial,Helvetica,sans-serif;color:{p['ink']};">
<div style="display:none;font-size:1px;line-height:1px;color:{p['background']};max-height:0;max-width:0;opacity:0;overflow:hidden;mso-hide:all;">{esc(preheader)}</div>
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" bgcolor="{p['background']}" style="background:{p['background']};"><tr><td class="outer" align="center" style="padding:40px 16px;">
<!--[if mso]><table role="presentation" width="600" cellpadding="0" cellspacing="0"><tr><td><![endif]-->
<table class="frame" role="presentation" width="100%" cellpadding="0" cellspacing="0" bgcolor="{p['surface']}" style="width:100%;max-width:600px;background:{p['surface']};{border}border-radius:{p['radius']}px;">
<tr><td class="pad" style="padding:30px 36px 0;font-size:10px;line-height:18px;letter-spacing:2px;color:{p['muted']};">{env}{p['eyebrow']}</td></tr>
<tr><td class="pad" style="padding:18px 36px 8px;color:{p['ink']};{mark_style}">{wordmark}</td></tr>
<tr><td class="pad" style="padding:0 36px 28px;color:{p['muted']};font-size:14px;line-height:22px;">{p['tagline']}</td></tr>
{ornament}
<tr><td class="pad" style="padding:4px 36px 12px;font-size:11px;font-weight:bold;letter-spacing:2px;color:{p['accent'] if b['layout']!='paper' else '#23733b'};">{esc(label)}</td></tr>
<tr><td class="pad" style="padding:0 36px 24px;"><h1 class="heading" style="margin:0;font-size:34px;line-height:42px;letter-spacing:-1px;font-weight:700;word-break:break-word;overflow-wrap:anywhere;color:{p['ink']};">{esc(title)}</h1></td></tr>
<tr><td class="pad" style="padding:0 36px 4px;color:{p['ink']};">{paragraphs}</td></tr>
{action}
<tr><td class="pad" style="padding:0 36px 30px;"><table role="presentation" width="100%" cellpadding="0" cellspacing="0"><tr><td style="border-top:1px solid {p['line']};padding-top:18px;font-size:12px;line-height:20px;color:{p['muted']};">{esc(security_note)}</td></tr></table></td></tr>
<tr><td class="pad" style="padding:20px 36px;border-top:1px solid {p['line']};font-size:12px;line-height:20px;color:{p['muted']};">{p['footer']}</td></tr>
</table>
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:600px;"><tr><td align="center" style="padding:20px 24px 0;font-size:11px;line-height:18px;color:{p['muted']};">{p['name']} · Account email<br>You received this email about your {p['name']} account. We will never ask you to reply with a password.</td></tr></table>
<!--[if mso]></td></tr></table><![endif]-->
</td></tr></table></body></html>'''
