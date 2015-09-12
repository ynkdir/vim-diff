let s:normal = diff#normal#import()
let s:wuonp = diff#wuonp#import()

function diff#diffexpr()
  call diff#fnormal(v:fname_in, v:fname_new, v:fname_out)
endfunction

function diff#normal(old, new)
  let diff = s:Diff.new(a:old, a:new)
  let out = diff.format_normal()
  return out
endfunction

function diff#bnormal(old, new)
  let iwhite = (&diffopt =~ 'iwhite')
  let icase = (&diffopt =~ 'icase')
  let [A, Aeol] = s:fixeol(copy(a:old))
  let [B, Beol] = s:fixeol(copy(a:new))
  let Acmp = s:makecmpbuf(copy(A), Aeol, iwhite, icase)
  let Bcmp = s:makecmpbuf(copy(B), Beol, iwhite, icase)
  let path = s:wuonp.WuOnpDiff.diff(Acmp, Bcmp)
  return s:normal.Normal.format(path, A, Aeol, B, Beol)
endfunction

function diff#fnormal(oldfile, newfile, outfile)
  let old = readfile(a:oldfile, 'b')
  let new = readfile(a:newfile, 'b')
  let out = diff#bnormal(old, new)
  if !empty(out)
    call add(out, '')
  endif
  call writefile(out, a:outfile, 'b')
endfunction

function s:fixeol(lines)
  let eol = 0
  if !empty(a:lines) && a:lines[-1] == ''
    let eol = 1
    unlet a:lines[-1]
  endif
  return [a:lines, eol]
endfunction

function s:makecmpbuf(lines, eol, iwhite, icase)
  " Add \n to detect noeol.
  call map(a:lines, 'v:val . "\n"')
  if !empty(a:lines) && !a:eol
    let a:lines[-1] = a:lines[-1][0:-2]
  endif
  if a:iwhite
    call map(a:lines, 'substitute(v:val, ''[ \t\r\n]\+\|[ \t\r\n]*$'', " ", "g")')
  endif
  if a:icase
    call map(a:lines, 'tolower(v:val)')
  endif
  return a:lines
endfunction
