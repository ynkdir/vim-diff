
let s:dir = expand('<sfile>:p:h')

function! s:sysdiff(oldfile, newfile)
  return split(system(printf('diff %s %s', shellescape(a:oldfile), shellescape(a:newfile))), '\n')
endfunction

function! s:test(name)
  echo a:name
  let oldfile = printf('%s/%s_old.txt', s:dir, a:name)
  let newfile = printf('%s/%s_new.txt', s:dir, a:name)
  let a = diff#normal(readfile(oldfile, 'b'), readfile(newfile, 'b'))
  let b = s:sysdiff(oldfile, newfile)
  let c = diff#normal(readfile(newfile, 'b'), readfile(oldfile, 'b'))
  let d = s:sysdiff(newfile, oldfile)
  if a != b || c != d
    echoerr printf('%s failed', a:name)
  endif
endfunction

let i = 1
while filereadable(printf('%s/test%d_old.txt', s:dir, i))
  call s:test(printf('test%d', i))
  let i += 1
endwhile
