let s:normal = diff#normal#import()
let s:wuonp = diff#wuonp#import()
let s:histogram = diff#histogram#import()
let s:patience = diff#patience#import()

function diff#diffexpr()
  let options = {}
  let options.algorithm = 'wuonp'
  let options.iwhite = (&diffopt =~ 'iwhite')
  let options.icase = (&diffopt =~ 'icase')
  call diff#fnormal(v:fname_in, v:fname_new, v:fname_out, options)
endfunction

function diff#histogramdiffexpr()
  let options = {}
  let options.algorithm = 'histogram'
  let options.iwhite = (&diffopt =~ 'iwhite')
  let options.icase = (&diffopt =~ 'icase')
  call diff#fnormal(v:fname_in, v:fname_new, v:fname_out, options)
endfunction

function diff#patiencediffexpr()
  let options = {}
  let options.algorithm = 'patience'
  let options.iwhite = (&diffopt =~ 'iwhite')
  let options.icase = (&diffopt =~ 'icase')
  call diff#fnormal(v:fname_in, v:fname_new, v:fname_out, options)
endfunction

function diff#normal(old, new, ...)
  let options = get(a:000, 0, {})
  return diff#bnormal(a:old + [''], a:new + [''], options)
endfunction

function diff#bnormal(old, new, ...)
  let options = get(a:000, 0, {})
  let algorithm = get(options, 'algorithm', 'wuonp')
  let iwhite = get(options, 'iwhite', 0)
  let icase = get(options, 'icase', 0)
  let [A, Aeol] = s:fixeol(copy(a:old))
  let [B, Beol] = s:fixeol(copy(a:new))
  let Acmp = s:makecmpbuf(copy(A), Aeol, iwhite, icase)
  let Bcmp = s:makecmpbuf(copy(B), Beol, iwhite, icase)
  if algorithm == 'histogram'
    let path = s:histogram.HistogramDiff.diff(Acmp, Bcmp)
  elseif algorithm == 'patience'
    let path = s:patience.PatienceDiff.diff(Acmp, Bcmp)
  elseif algorithm == 'wuonp'
    let path = s:wuonp.WuOnpDiff.diff(Acmp, Bcmp)
  else
    throw 'Unknown algorithm: ' . algorithm
  endif
  return s:normal.Normal.format(path, A, Aeol, B, Beol)
endfunction

function diff#fnormal(oldfile, newfile, outfile, ...)
  let options = get(a:000, 0, {})
  let old = readfile(a:oldfile, 'b')
  let new = readfile(a:newfile, 'b')
  let out = diff#bnormal(old, new, options)
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
  " Add x to avoid empty key for Dictionary.
  " Add \n to detect noeol.
  call map(a:lines, '"x" . v:val . "\n"')
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
