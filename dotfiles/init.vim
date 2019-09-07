call plug#begin('~/.local/share/nvim/plugged')

	Plug 'editorconfig/editorconfig-vim'

        Plug 'autozimu/LanguageClient-neovim', {
            \ 'branch': 'next',
            \ 'do': 'bash install.sh',
            \ }

	" Code completion engine
	Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }

	" NERDTree
	Plug 'scrooloose/nerdtree'
	Plug 'Xuyuanp/nerdtree-git-plugin'

	" Fuzzy-file search
	Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
	Plug 'junegunn/fzf.vim'

	" Snippets
	Plug 'Shougo/neosnippet.vim'
	Plug 'Shougo/neosnippet-snippets'

	" Neomake
	Plug 'neomake/neomake'

	" Go stuff
	Plug 'fatih/vim-go'
	Plug 'nsf/gocode'
	Plug 'zchee/deoplete-go', { 'do': 'make'}

	Plug 'janko-m/vim-test'

	" The silver searcher
	Plug 'rking/ag.vim'

	"Python stuff
	Plug 'zchee/deoplete-jedi'
	Plug 'nvie/vim-flake8'

	" Rust stuff
	Plug 'rust-lang/rust.vim'
	Plug 'racer-rust/vim-racer'
	Plug 'majutsushi/tagbar'

	" Pope's utilities
	Plug 'tpope/vim-surround'
	Plug 'tpope/vim-repeat'
	Plug 'tpope/vim-fugitive'
	Plug 'tpope/vim-eunuch'
	Plug 'tpope/vim-commentary'

	" Airline
	Plug 'vim-airline/vim-airline'
	Plug 'ryanoasis/vim-devicons'
	Plug 'hashivim/vim-packer'
	Plug 'hashivim/vim-terraform'

	" Color schemes
	Plug 'nightsense/seagrey'
	Plug 'nightsense/office'
	Plug 'nightsense/nemo'
	Plug 'hzchirs/vim-material'
	Plug 'crusoexia/vim-monokai'


call plug#end()

set termguicolors

colorscheme monokai

set number
set autowrite

autocmd BufWritePre * :%s/\s\+$//e

set colorcolumn=+1
set textwidth=80
set mouse=a

" NEOMAKE
" Full config: when writing or reading a buffer, and on changes in insert and
" normal mode (after 1s; no delay when writing).
" call neomake#configure#automake('nrwi', 500)


autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab

" Python integration
let g:python2_host_prog = '/usr/local/bin/python'
let g:python3_host_prog = '/usr/local/bin/python3'

" Python
autocmd FileType python nnoremap <leader>y :0,$!yapf<Cr>
autocmd CompleteDone * pclose " To close preview window of deoplete automagically

let g:flake8_cmd="/Users/jz/.pyenv/shims/flake8"


" vim-test & Python
let test#python#runner = 'pytest'
let test#python#pytest#executable = 'pipenv run pytest'


" LSP
let g:LanguageClient_serverCommands = {
    \ 'rust': ['~/.cargo/bin/rustup', 'run', 'stable', 'rls'],
    \ 'python': ['/usr/local/bin/pyls'],
    \ }

" Plugin key-mappings.
" Note: It must be "imap" and "smap".  It uses <Plug> mappings.
imap <C-k>     <Plug>(neosnippet_expand_or_jump)
smap <C-k>     <Plug>(neosnippet_expand_or_jump)
xmap <C-k>     <Plug>(neosnippet_expand_target)

" SuperTab like snippets behavior.
" Note: It must be "imap" and "smap".  It uses <Plug> mappings.
"imap <expr><TAB>
" \ pumvisible() ? "\<C-n>" :
" \ neosnippet#expandable_or_jumpable() ?
" \    "\<Plug>(neosnippet_expand_or_jump)" : "\<TAB>"
smap <expr><TAB> neosnippet#expandable_or_jumpable() ?
\ "\<Plug>(neosnippet_expand_or_jump)" : "\<TAB>"


"Rust Racer related
set hidden
let g:racer_cmd = "/usr/local/bin/racer"
let g:rust_clip_command = 'pbcopy'
let g:rustfmt_autosave = 1
nnoremap <C-b> :Cargo build<CR>


" Go config
au FileType go set noexpandtab
au FileType go set shiftwidth=4
au FileType go set softtabstop=4
au FileType go set tabstop=4

let g:go_highlight_build_constraints = 1
let g:go_highlight_extra_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_operators = 1
let g:go_highlight_structs = 1
let g:go_highlight_types = 1
let g:go_auto_sameids = 1

" Error and warning signs.
let g:ale_sign_error = '⤫'
let g:ale_sign_warning = '⚠'
" Enable integration with airline.
let g:airline#extensions#ale#enabled = 1

let g:deoplete#enable_at_startup = 1

" NERDTree
map <C-n> :NERDTreeToggle<CR>

let mapleader = ","

" Fuzzy file search
nnoremap <C-p> :FZF<CR>



