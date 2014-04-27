if has('vim_starting')
  set nocompatible               " Be iMproved
  set runtimepath+=~/.vim/bundle/neobundle.vim/
endif

nnoremap <ESC><ESC> :nohlsearch<CR>

call neobundle#rc(expand('~/.vim/bundle/'))

" Let NeoBundle manage NeoBundle
NeoBundleFetch 'Shougo/neobundle.vim'

NeoBundle 'Shougo/vimproc.vim', { 'build' : { 'unix' : 'make -f make_unix.mak' } }
NeoBundle "Shougo/neocomplete.vim"
NeoBundle 'Shougo/neosnippet'
NeoBundle 'Shougo/neosnippet-snippets'
NeoBundle 'vim-scripts/javacomplete'
NeoBundle 'osyo-manga/vim-over'
"NeoBundle 'soramugi/auto-ctags.vim'


syntax on
filetype on
filetype plugin indent on   " Required!

:let java_highlight_all=1

NeoBundleCheck


" ...(NeoBundleとneocomplete以外の設定は省略)...


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
