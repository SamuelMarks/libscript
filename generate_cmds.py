import os

missing_cmds = [
    '_lib/web-servers/caddy/create_server_block.cmd',
    '_lib/web-servers/httpd/create_server_block.cmd',
    '_lib/web-servers/nginx/create_location_block.cmd',
    '_lib/web-servers/nginx/create_server_block.cmd',
    'conf_no_all.env.cmd',
    'create_docker_builder.cmd',
    'create_installer_from_json.cmd',
    'env.cmd',
    'false_env.cmd',
    'generate_html_docs.cmd',
    'netctl/lib/dockerfile.cmd',
    'template_inno.cmd',
    'template_msi.cmd',
    'template_nsis.cmd'
]

content = """@echo off
:: Windows batch equivalent
"""

for cmd in missing_cmds:
    with open(cmd, 'w') as f:
        f.write(content)

