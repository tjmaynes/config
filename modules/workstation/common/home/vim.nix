{ pkgs, ... }:
{
  programs.vim = {
    enable = true;
    defaultEditor = false;
    plugins = with pkgs.vimPlugins; [
      nerdtree
      ctrlp-vim
      vim-fugitive
      vim-commentary
      vim-surround
      vim-gnupg
      editorconfig-vim
      papercolor-theme
      vim-markdown
      goyo-vim
      vim-pencil
    ];
    settings = {
      background = "dark";
      history = 100;
      modeline = true;
      number = true;
      relativenumber = true;
      expandtab = true;
      shiftwidth = 2;
      tabstop = 2;
    };
    extraConfig = ''
      set nocompatible
      set encoding=utf-8
      set lazyredraw
      set ttyfast
      set synmaxcol=300
      syntax on
      filetype indent on
      set autochdir
      set autoread
      set autowrite
      set backspace=indent,eol,start
      set showmatch
      set showcmd
      set novisualbell
      set linespace=0
      set foldlevel=99
      set foldmethod=indent
      set hidden
      set hlsearch
      set incsearch
      set wildmenu
      set wildmode=longest,list,full
      set completeopt+=longest
      set omnifunc=syntaxcomplete#Complete

      nnoremap <C-n> :bnext<cr>
      nnoremap <C-p> :previous<cr>
      nnoremap <C-J> <C-W><C-J>
      nnoremap <C-K> <C-W><C-K>
      nnoremap <C-L> <C-W><C-L>
      nnoremap <C-H> <C-W><C-H>
      nnoremap <space> za
      nmap <silent> <leader>w :w!<cr>
      nmap <silent> <leader>. :tabnext<cr>
      nmap <silent> <leader>/ :tabnext<cr>
      nmap <silent> <leader>q :r! date +"\%Y-\%m-\%d \%H:\%M:\%S"<cr>

      autocmd BufNewFile,BufRead .babelrc setf json
      autocmd BufNewFile,BufRead *.py
            \ set tabstop=4 |
            \ set softtabstop=4 |
            \ set shiftwidth=4 |
            \ set textwidth=79 |
            \ set expandtab |
            \ set autoindent |
            \ set fileformat=unix
      autocmd BufNewFile,BufRead *.js,*.html,*.css
            \ set tabstop=2 |
            \ set softtabstop=2 |
            \ set shiftwidth=2

      let g:NERDTreeShowHidden = 1
      let g:NERDTreeIgnore = ['\.pyc$', '\~$']
      let g:NERDTreeQuitOnOpen = 0
      let g:NERDTreeDirArrows = 1
      let g:NERDTreeMinimalUI = 1
      map <silent> <leader>d :execute 'NERDTreeToggle ' . getcwd()<cr>
      map <silent> <leader>b :NERDTreeFromBookmark<cr>

      let g:jsx_ext_required = 0

      augroup pencil
        autocmd!
        autocmd FileType markdown,mkd call pencil#init({ 'wrap': 'soft' })
        autocmd FileType text call pencil#init({ 'wrap': 'hard', 'autocorrect': 1 })
      augroup END

      command PyJSONPretty execute "%!python -m json.tool"
      nnoremap <leader>j :PyJSONPretty<cr>
    '';
  };
}
