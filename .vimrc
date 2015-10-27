if has('vim_starting')
"set nocompatible               " Be iMproved
  set runtimepath+=~/.vim/bundle/neobundle.vim/
endif

nnoremap <ESC><ESC> :nohlsearch<CR>

call neobundle#begin(expand('~/.vim/bundle/'))

" Let NeoBundle manage NeoBundle
NeoBundleFetch 'Shougo/neobundle.vim'

let OSTYPE = system('uname')

if OSTYPE == "Darwin\n"
	NeoBundle "Shougo/neocomplcache.vim"
	" Ruby向けにendを自動挿入してくれる
	NeoBundle 'tpope/vim-endwise'
elseif OSTYPE == "Linux\n"
	" コマンドラインに使われる画面上の行数
	set cmdheight=1
	" エディタウィンドウの末尾から2行目にステータスラインを常時表示させる
	set laststatus=2
	" ステータス行に表示させる情報の指定(どこからかコピペしたので細かい意味はわかっていない)
	set statusline=%<%f\ %m%r%h%w%{'['.(&fenc!=''?&fenc:&enc).']['.&ff.']'}%=%l,%c%V%8P
	" ステータス行に現在のgitブランチを表示する
	"set statusline+=%{fugitive#statusline()}
	NeoBundle 'Shougo/vimproc.vim', { 'build' : { 'unix' : 'make -f make_unix.mak' } }
	NeoBundle "Shougo/neocomplete.vim"
endif
" ファイルオープンを便利に
NeoBundle 'Shougo/unite.vim'
" Unite.vimで最近使ったファイルを表示できるようにする
NeoBundle 'Shougo/neomru.vim'
NeoBundle 'Shougo/neosnippet'
NeoBundle 'Shougo/neosnippet-snippets'
NeoBundle 'vim-scripts/javacomplete'
NeoBundle 'osyo-manga/vim-over'
"NeoBundle 'soramugi/auto-ctags.vim'
NeoBundle "tyru/caw.vim"
" インデントに色を付けて見やすくする
NeoBundle 'nathanaelkane/vim-indent-guides'
" 行末の半角スペースを可視化
NeoBundle 'bronson/vim-trailing-whitespace'

" Gitを便利に使う
NeoBundle 'tpope/vim-fugitive'
" ColorScheme
NeoBundle 'tomasr/molokai'
" SpellChecker
NeoBundle 'rhysd/vim-grammarous'
" for editing commit message
NeoBundle 'rhysd/committia.vim'

NeoBundle 'justmao945/vim-clang'

" grep検索の実行後にQuickFix Listを表示する
autocmd QuickFixCmdPost *grep* cwindow

" ステータス行に現在のgitブランチを表示する
"set statusline+=%{fugitive#statusline()}

syntax on
filetype on
filetype plugin indent on   " Required!


NeoBundleCheck


" ...(NeoBundleとneocomplete以外の設定は省略)...


:let java_highlight_all=1
"==========================================
"neocomplete.vim
"==========================================
"use neocomplete.
let g:neocomplete#enable_at_startup = 1
" Use smartcase.
let g:neocomplete#enable_smart_case = 1
" Set minimum syntax keyword length.
let g:neocomplete#sources#syntax#min_keyword_length = 3
let g:neocomplete#lock_buffer_name_pattern = '¥*ku¥*'
" Define keyword.
if !exists('g:neocomplete#keyword_patterns')
  let g:neocomplete#keyword_patterns = {}
endif
let g:neocomplete#keyword_patterns['default'] = '¥h¥w*'

call neobundle#end()
" Plugin key-mappings.
inoremap <expr><C-g>  neocomplete#undo_completion()
inoremap <expr><C-l>  neocomplete#complete_common_string()

"" over.vim {{{

" over.vimの起動
nnoremap <silent> <Leader>m :OverCommandLine<CR>
"
" " カーソル下の単語をハイライト付きで置換
" nnoremap sub :OverCommandLine<CR>%s/<C-r><C-w>//g<Left><Left>
"
" " コピーした文字列をハイライト付きで置換
" nnoremap subp y:OverCommandLine<CR>%s!<C-r>=substitute(@0, '!', '\\!',
" 'g')<CR>!!gI<Left><Left><Left>
"
" " }}}

" Plugin key-mappings.
imap <C-k>     <Plug>(neosnippet_expand_or_jump)
smap <C-k>     <Plug>(neosnippet_expand_or_jump)
xmap <C-k>     <Plug>(neosnippet_expand_target)

" SuperTab like snippets behavior.
imap <expr><TAB> neosnippet#expandable_or_jumpable() ?
\ "\<Plug>(neosnippet_expand_or_jump)"
\: pumvisible() ? "\<C-n>" : "\<TAB>"
smap <expr><TAB> neosnippet#expandable_or_jumpable() ?
\ "\<Plug>(neosnippet_expand_or_jump)"
\: "\<TAB>"

" For snippet_complete marker.
if has('conceal')
  set conceallevel=2 concealcursor=i
endif



"" auto-ctags.vim {{{
let g:auto_ctags = 0
"" }}}

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

let g:clang_c_options = '-std=gnu11'
let g:clang_cpp_options = '-std=c++11 -stdlib=libc++'

" vimを立ち上げたときに、自動的にvim-indent-guidesをオンにする
let g:indent_guides_enable_on_vim_startup = 1
"let g:indent_guides_guide_size=1

nmap <Leader>c <Plug>(caw:i:toggle)
vmap <Leader>c <Plug>(caw:i:toggle)

set fileencodings=utf-8,iso-2022-jp,cp932,sjis,euc-jp,default
colorscheme molokai
