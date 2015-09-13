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
  let path = s:change_compact(path, Acmp, Bcmp)
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
  if !empty(a:lines) && a:lines[-1] ==# ''
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

" Move back and forward change groups for a consistent and pretty diff output.
function s:change_compact(path, al, bl)
  let [ad, bd] = s:path_to_diff(a:path)
  let ad = s:change_compact_sub(ad, a:al)
  let bd = s:change_compact_sub(bd, a:bl)
  return s:diff_to_path(ad, bd)
endfunction

function s:path_to_diff(path)
  let ad = filter(copy(a:path), 'v:val <= 0')
  let bd = filter(copy(a:path), 'v:val >= 0')
  return [ad, bd]
endfunction

function s:diff_to_path(ad, bd)
  let path = []
  let a = 0
  let b = 0
  while a < len(a:ad) && b < len(a:bd)
    if a:ad[a] == 0 && a:bd[b] == 0
      call add(path, 0)
      let a += 1
      let b += 1
    elseif a:ad[a] != 0
      call add(path, -1)
      let a += 1
    else
      call add(path, 1)
      let b += 1
    endif
  endwhile
  if a < len(a:ad)
    while a < len(a:ad)
      call add(path, -1)
      let a += 1
    endwhile
  endif
  if b < len(a:bd)
    while b < len(a:bd)
      call add(path, 1)
      let b += 1
    endwhile
  endif
  return path
endfunction

function s:change_compact_sub(diff, lines)
  let i = 0
  while i < len(a:diff)
    while i < len(a:diff) && a:diff[i] == 0
      let i += 1
    endwhile
    let s = i
    while i < len(a:diff) && a:diff[i] != 0
      let i += 1
    endwhile
    let e = i
    if s == e
      break
    endif
    let start = s
    let end = e
    while 0 < s && a:lines[s - 1] ==# a:lines[e - 1]
      let a:diff[s - 1] = a:diff[e - 1]
      let a:diff[e - 1] = 0
      let e -= 1
      while 0 < s && a:diff[s - 1] != 0
        let s -= 1
      endwhile
    endwhile
    while e < len(a:lines) && a:lines[s] ==# a:lines[e]
      let a:diff[e] = a:diff[s]
      let a:diff[s] = 0
      let s += 1
      while e < len(a:diff) && a:diff[e] != 0
        let e += 1
      endwhile
    endwhile
    if start != s || end != e
      let i = s
    else
      let i = e
    endif
  endwhile
  return a:diff
endfunction
