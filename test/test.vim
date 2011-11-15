
let s:dir = expand('<sfile>:p:h')

function! s:sysdiff(oldfile, newfile)
  return system(printf('diff %s %s', shellescape(a:oldfile), shellescape(a:newfile)))
endfunction

function! s:test(name)
  let oldfile = printf('%s/%s_old.txt', s:dir, a:name)
  let newfile = printf('%s/%s_new.txt', s:dir, a:name)
  let a = diff#ed(readfile(oldfile, 'b'), readfile(newfile, 'b'))
  let b = s:sysdiff(oldfile, newfile)
  let c = diff#ed(readfile(newfile, 'b'), readfile(oldfile, 'b'))
  let d = s:sysdiff(newfile, oldfile)
  if a != b || c != d
    echoerr printf('%s failed', a:name)
  endif
endfunction

call s:test('test1')
call s:test('test2')
call s:test('test3')
call s:test('test4')
call s:test('test5')
call s:test('test6')
call s:test('test7')
