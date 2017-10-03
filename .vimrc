if &compatible
	set nocompatible
endif

let s:dein_dir = expand('~/.cache/dein')
let s:dein_repo_dir = s:dein_dir . '/repos/github.com/Shougo/dein.vim'

if !isdirectory(s:dein_repo_dir)
	execute '!git clone https://github.com/Shougo/dein.vim' s:dein_repo_dir
endif
execute 'set runtimepath^=' . s:dein_repo_dir

if dein#load_state(s:dein_dir)
	call dein#begin(s:dein_dir)
	let s:toml = '~/.dein.toml'
	let s:lazy_toml = '~/.dein_lazy.toml'
	call dein#load_toml(s:toml, {'lazy': 0})
	call dein#load_toml(s:lazy_toml, {'lazy': 1})

	call dein#add('Shougo/vimproc.vim', {'build' : 'make'})
	if dein#check_install()
		call dein#install()
	endif

	call dein#end()
	call dein#save_state()
endif

if has('vim_starting')
	set runtimepath+=~/.vim/bundle/neobundle.vim/
endif

"if dein#check_install(['Shougo/vimproc.vim'])
"	call dein#install(['Shougo/vimproc.vim'])
"endif

nnoremap <ESC><ESC> :nohlsearch<CR>

syntax enable
filetype on
filetype plugin indent on

" カーソルが何行目の何列目に置かれているかを表示する
set ruler
" ウインドウのタイトルバーにファイルのパス情報等を表示する
set title
" コマンドラインモードで<Tab>キーによるファイル名補完を有効にする
set wildmenu
" 入力中のコマンドを表示する
set showcmd
set display=lastline
set modeline
set modelines=2
set backspace=indent,eol,start
set tabstop=4
set shiftwidth=4
set softtabstop=4
set autoindent
set smartindent
if has('nvim')
	set termguicolors
endif
" コマンドラインに使われる画面上の行数
set cmdheight=1
" エディタウィンドウの末尾から2行目にステータスラインを常時表示させる
set laststatus=2
" ステータス行に表示させる情報の指定(どこからかコピペしたので細かい意味はわかっていない)
set statusline=%<%f\ %m%r%h%w%{'['.(&fenc!=''?&fenc:&enc).']['.&ff.']'}%=%l,%c%V%8P
" ステータス行に現在のgitブランチを表示する
"set statusline+=%{fugitive#statusline()}

let g:indent_guides_enable_on_vim_startup = 1
let g:deoplete#enable_at_startup = 1

nmap <Leader>c <Plug>(caw:i:toggle)
vmap <Leader>c <Plug>(caw:i:toggle)

set fileencodings=utf-8,iso-2022-jp,cp932,sjis,euc-jp,default
colorscheme molokai
