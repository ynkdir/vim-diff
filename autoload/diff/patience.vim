" Patience Diff Advantages
" http://bramcohen.livejournal.com/73318.html
"
" Patience Diff, a brief summary
" http://alfedenzo.livejournal.com/170301.html
"
" 1. Match the first lines of both if they're identical, then match the
"    second, third, etc. until a pair doesn't match.
" 2. Match the last lines of both if they're identical, then match the next to
"    last, second to last, etc. until a pair doesn't match.
" 3. Find all lines which occur exactly once on both sides, then do longest
"    common subsequence on those lines, matching them up.
" 4. Do steps 1-2 on each section between matched lines

function diff#patience#import()
  return s:
endfunction

let s:wuonp = diff#wuonp#import()

let s:PatienceDiff = {}

function s:PatienceDiff.diff(A, B)
  return self.new(a:A, a:B).path
endfunction

function s:PatienceDiff.new(...)
  let obj = deepcopy(self)
  call call(obj.__init__, a:000, obj)
  return obj
endfunction

function s:PatienceDiff.__init__(A, B)
  let self.path = self.patience_diff(a:A, 0, len(a:A), a:B, 0, len(a:B))
endfunction

function s:PatienceDiff.patience_diff(al, astart, aend, bl, bstart, bend)
  let path = []
  let stack = [[0, a:astart, a:aend, a:bstart, a:bend]]
  while !empty(stack)
    let [islcs, astart, aend, bstart, bend] = remove(stack, 0)
    if islcs
      let path += repeat([0], aend - astart)
      continue
    endif
    while astart < aend && bstart < bend && a:al[astart] ==# a:bl[bstart]
      let path += [0]
      let astart += 1
      let bstart += 1
    endwhile
    while astart < aend && bstart < bend && a:al[aend - 1] ==# a:bl[bend - 1]
      call insert(stack, [1, aend - 1, aend, bend - 1, bend])
      let aend -= 1
      let bend -= 1
    endwhile
    if astart == aend && bstart == bend
      continue
    elseif astart == aend || bstart == bend
      let path += repeat([-1], aend - astart) + repeat([1], bend - bstart)
      continue
    endif
    let ul = self.find_all_unique_common_lines(a:al, astart, aend, a:bl, bstart, bend)
    if len(ul) == 0
      let path += self.fallback_diff(a:al, astart, aend, a:bl, bstart, bend)
      continue
    endif
    let lcs = self.find_longest_common_subsequence(ul)
    let i = 0
    for r in lcs
      call insert(stack, [0, astart, r.aline, bstart, r.bline], i)
      let i += 1
      call insert(stack, [1, r.aline, r.aline + 1, r.bline, r.bline + 1], i)
      let i += 1
      let astart = r.aline + 1
      let bstart = r.bline + 1
    endfor
    if astart < aend || bstart < bend
      call insert(stack, [0, astart, aend, bstart, bend], i)
    endif
  endwhile
  return path
endfunction

function s:PatienceDiff.fallback_diff(al, astart, aend, bl, bstart, bend)
  let al = (a:astart == a:aend ? [] : a:al[a:astart : a:aend - 1])
  let bl = (a:bstart == a:bend ? [] : a:bl[a:bstart : a:bend - 1])
  return s:wuonp.WuOnpDiff.diff(al, bl)
endfunction

function s:PatienceDiff.find_all_unique_common_lines(al, astart, aend, bl, bstart, bend)
  let rm = {}
  for a in range(a:astart, a:aend - 1)
    if has_key(rm, a:al[a])
      let rm[a:al[a]].acount += 1
    else
      let rm[a:al[a]] = {'aline': a, 'acount': 1, 'bline': 0, 'bcount': 0, 'prev': {}}
    endif
  endfor
  for b in range(a:bstart, a:bend - 1)
    if has_key(rm, a:bl[b]) && rm[a:bl[b]].acount == 1
      let rm[a:bl[b]].bline = b
      let rm[a:bl[b]].bcount += 1
    endif
  endfor
  return filter(values(rm), 'v:val.acount == 1 && v:val.bcount == 1')
endfunction

function s:PatienceDiff.find_longest_common_subsequence(rl)
  " Either is fine.
  " call sort(a:rl, 's:bybline')
  call sort(a:rl, 's:byaline')
  let piles = []
  for r in a:rl
    " let i = s:bsearch(piles, r.aline)
    let i = s:bsearch(piles, r.bline)
    if i != 0
      let r.prev = piles[i - 1]
    endif
    if i < len(piles)
      let piles[i] = r
    else
      let piles += [r]
    endif
  endfor
  let lcs = repeat([{}], len(piles))
  let i = len(piles) - 1
  let r = piles[i]
  while !empty(r)
    let lcs[i] = r
    let i -= 1
    let r = r.prev
  endwhile
  return lcs
endfunction

function s:byaline(a, b)
  return a:a.aline - a:b.aline
endfunction

function s:bsearch(piles, bline)
  let left = 0
  let right = len(a:piles)
  while left < right
    let mid = (left + right) / 2
    if a:piles[mid].bline < a:bline
      let left = mid + 1
    else
      let right = mid
    endif
  endwhile
  return left
endfunction
