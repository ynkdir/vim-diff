"===============================================================================
" https://github.com/eclipse/jgit/blob/master/org.eclipse.jgit/src/org/eclipse/jgit/diff/HistogramDiff.java
" https://github.com/git/git/blob/master/xdiff/xhistogram.c
"
" Copyright (C) 2010, Google Inc.
" and other copyright owners as documented in the project's IP log.
"
" This program and the accompanying materials are made available
" under the terms of the Eclipse Distribution License v1.0 which
" accompanies this distribution, is reproduced below, and is
" available at http://www.eclipse.org/org/documents/edl-v10.php
"
" All rights reserved.
"
" Redistribution and use in source and binary forms, with or
" without modification, are permitted provided that the following
" conditions are met:
"
" - Redistributions of source code must retain the above copyright
"   notice, this list of conditions and the following disclaimer.
"
" - Redistributions in binary form must reproduce the above
"   copyright notice, this list of conditions and the following
"   disclaimer in the documentation and/or other materials provided
"   with the distribution.
"
" - Neither the name of the Eclipse Foundation, Inc. nor the
"   names of its contributors may be used to endorse or promote
"   products derived from this software without specific prior
"   written permission.
"
" THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
" CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
" INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
" OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
" ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
" CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
" SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
" NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
" LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
" CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
" STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
" ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
" ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
"===============================================================================

function diff#histogram#import()
  return s:
endfunction

let s:wuonp = diff#wuonp#import()

let s:HistogramDiff = {}

let s:HistogramDiff.MAX_OCCURRENCE = 64

function s:HistogramDiff.diff(A, B)
  return self.new(a:A, a:B).path
endfunction

function s:HistogramDiff.new(...)
  let obj = deepcopy(self)
  call call(obj.__init__, a:000, obj)
  return obj
endfunction

function s:HistogramDiff.__init__(A, B)
  let self.path = self.histogram_diff(a:A, 0, len(a:A), a:B, 0, len(a:B))
endfunction

function s:HistogramDiff.histogram_diff(al, astart, aend, bl, bstart, bend)
  let path = []
  let stack = [[0, a:astart, a:aend, a:bstart, a:bend]]
  while !empty(stack)
    let [islcs, astart, aend, bstart, bend] = remove(stack, 0)
    if islcs
      let path += repeat([0], aend - astart)
      continue
    endif
    if astart == aend && bstart == bend
      continue
    elseif astart == aend || bstart == bend
      let path += repeat([-1], aend - astart) + repeat([1], bend - bstart)
      continue
    endif
    let index = {}
    let index.rm = {}
    let index.count = self.MAX_OCCURRENCE
    let index.lcs = {'astart': 0, 'aend': 0, 'bstart': 0, 'bend': 0}
    let index.has_common = 0
    let index.has_lcs = 0
    call self.find_lcs(index, a:al, astart, aend, a:bl, bstart, bend)
    if !index.has_lcs
      if index.has_common
        let path += self.fallback_diff(a:al, astart, aend, a:bl, bstart, bend)
        continue
      else
        let path += repeat([-1], aend - astart) + repeat([1], bend - bstart)
        continue
      endif
    endif
    call insert(stack, [0, index.lcs.aend, aend, index.lcs.bend, bend])
    call insert(stack, [1, index.lcs.astart, index.lcs.aend, index.lcs.bstart, index.lcs.bend])
    call insert(stack, [0, astart, index.lcs.astart, bstart, index.lcs.bstart])
  endwhile
  return path
endfunction

function s:HistogramDiff.fallback_diff(al, astart, aend, bl, bstart, bend)
  let al = (a:astart == a:aend ? [] : a:al[a:astart : a:aend - 1])
  let bl = (a:bstart == a:bend ? [] : a:bl[a:bstart : a:bend - 1])
  return s:wuonp.WuOnpDiff.diff(al, bl)
endfunction

function s:HistogramDiff.find_lcs(index, al, astart, aend, bl, bstart, bend)
  call self.scanA(a:index, a:al, a:astart, a:aend)
  let b = a:bstart
  while b < a:bend
    let b = self.try_lcs(a:index, b, a:al, a:astart, a:aend, a:bl, a:bstart, a:bend)
  endwhile
endfunction

function s:HistogramDiff.scanA(index, al, astart, aend)
  for a in range(a:astart, a:aend - 1)
    if has_key(a:index.rm, a:al[a])
      let a:index.rm[a:al[a]] += [a]
    else
      let a:index.rm[a:al[a]] = [a]
    endif
  endfor
endfunction

function s:HistogramDiff.try_lcs(index, b, al, astart, aend, bl, bstart, bend)
  let b_next = a:b + 1
  if !has_key(a:index.rm, a:bl[a:b])
    return b_next
  endif
  let lines = a:index.rm[a:bl[a:b]]
  let a:index.has_common = 1
  if len(lines) > a:index.count
    return b_next
  endif
  let prev_ae = 0
  for a in lines
    if a < prev_ae
      continue
    endif
    let as = a
    let ae = a + 1
    let bs = a:b
    let be = a:b + 1
    let rc = len(lines)
    while a:astart < as && a:bstart < bs && a:al[as - 1] == a:bl[bs - 1]
      let as -= 1
      let bs -= 1
      if len(a:index.rm[a:al[as]]) < rc
        let rc = len(a:index.rm[a:al[as]])
      endif
    endwhile
    while ae < a:aend && be < a:bend && a:al[ae] == a:bl[be]
      let ae += 1
      let be += 1
      if len(a:index.rm[a:al[ae - 1]]) < rc
        let rc = len(a:index.rm[a:al[ae - 1]])
      endif
    endwhile
    if b_next < be
      let b_next = be
    endif
    if a:index.lcs.aend - a:index.lcs.astart < ae - as || rc < a:index.count
      let a:index.lcs.astart = as
      let a:index.lcs.aend = ae
      let a:index.lcs.bstart = bs
      let a:index.lcs.bend = be
      let a:index.count = rc
      let a:index.has_lcs = 1
    endif
    let prev_ae = ae
  endfor
  return b_next
endfunction
