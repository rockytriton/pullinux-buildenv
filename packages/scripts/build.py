import yaml
import sys
import os
from subprocess import Popen, PIPE, DEVNULL
import shutil

try:
    import requests
except ImportError:
    print('WARN: cant load requests yet, so no downloads...')

plx_base = '/usr/share/plx'

if len(sys.argv) > 2:
	plx_base = sys.argv[2]

base_repo = plx_base + '/repo/'
dl_cache = plx_base + '/dl/'
cwd = os.getcwd()

pck = sys.argv[1]
l0 = pck[0]

full_path = base_repo + l0 + '/' + pck + '/.pck'

print('checking: ', full_path)

def download_file(url):
	bn = os.path.basename(url)

	if os.path.exists(dl_cache + bn):
		print('File ' + bn + ' already cached')
		return dl_cache + bn
	
	r = requests.get(url)

	with open(dl_cache + bn, 'wb') as f:
		f.write(r.content)
	
	print('downloaded file: ' + bn)

	return dl_cache + bn

installed_list = []
if os.path.exists('/usr/share/plx/installed'):
	with open("/usr/share/plx/installed") as fo:
		installed_list = fo.read().splitlines()

#print('Installed List: ', installed_list)

if not os.path.exists(full_path):
	print('Package', pck, 'Does not exist')
	sys.exit(1)

print('Loading package details..')

data = yaml.safe_load(open(full_path, 'r'))

data['filename'] = os.path.basename(data['source'])

if 'deps' in data:
	for d in data['deps']:
		if not d in installed_list:
			print('Missing dependency: ' + d)
			sys.exit(-2)

if 'mkdeps' in data:
	for d in data['mkdeps']:
		if not d in installed_list:
			print('Missing make dependency: ' + d)
			sys.exit(-2)

print('checking for file: ', data['filename'])

if data['filename'] == 'none':
	data['filename'] = None

if not data['filename'] == None and not os.path.exists(dl_cache + data['filename']):
	url = data['source']
	download_file(url)

tmpdir = '/tmp/build_' + data['name']

shutil.rmtree(tmpdir, ignore_errors=True)

os.mkdir(tmpdir)
os.mkdir(tmpdir + '/pckdir')

os.chdir(tmpdir)

if 'extras' in data:
	for e in data['extras']:
		file = base_repo + l0 + '/' + pck + '/' + e

		print('Copying extra file: ' + e)

		if e.startswith('https://'):
			f = download_file(e)
			shutil.copy2(f, tmpdir + '/' + os.path.basename(e))
		elif os.path.isdir(e):
			shutil.copytree(file, tmpdir + '/' + e)
		else:
			shutil.copy2(file, tmpdir + '/' + e)

if os.path.exists(base_repo + l0 + '/' + pck + '/.install'):
	shutil.copytree(base_repo + l0 + '/' + pck + '/.install', tmpdir + '/pckdir/.install')

if data['filename'] != None:
	shutil.copyfile(dl_cache + data['filename'], tmpdir + '/' + data['filename'])
	os.environ["filename"] = data['filename']

os.environ['tmpdir'] = tmpdir
os.environ['pckdir'] = tmpdir + '/pckdir'
os.environ['MAKEFLAGS'] = '-j' + str(os.cpu_count())

shutil.copyfile(full_path, tmpdir + '/pckdir/.pck')

print('building...')

p = Popen('bash -e ' + base_repo + l0 + '/' + pck + '/.build', universal_newlines=True, shell=True)

if p.wait() != 0:
	print('Failed to build ' + pck)
	sys.exit(-2)


pckfile = plx_base + '/bin/' + data['name'] + '-' + str(data['version']) + '-pullinux-aarch64-1.3.0.txz'

print('Packaging ' + pckfile)

p = Popen('tar -cJpf ' + pckfile + ' -C ' + tmpdir + '/pckdir .', shell=True)

if p.wait() != 0:
	print('failed to create package file: ' + pckfile)
	sys.exit(-3)

print('cleaning up...')
shutil.rmtree(tmpdir)

print(' ')
print('build complete')

print(' ')
print('installing...')

os.chdir('/')
p = Popen('tar -xhf ' + pckfile, shell=True)

if p.wait() != 0:
	print('Failed to install ' + pck)
	sys.exit(-3)

if os.path.exists('/.install'):
	os.chdir('/.install')

	p = Popen('bash -e /.install/install.sh', universal_newlines=True, shell=True)

	if p.wait() != 0:
		print('Install script failed ' + pck)
		sys.exit(-3)
	
	print('Ran installer script successfully')

	os.chdir('/')
	shutil.rmtree('/.install', ignore_errors=True)
	shutil.rmtree('/.pck', ignore_errors=True)

if os.path.exists('/usr/share/plx/installed'):
	with open("/usr/share/plx/installed", "a") as file_object:
		file_object.write('\n')
		file_object.write(data['name'])

print('Installed package: ' + pck)
