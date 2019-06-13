#usage: ruby domino.rb output_filename height width suits(0-6) [random_seed]
#  e.g. ruby domino.rb foo.html 4 5 01234
#       ruby domino.rb bar.html 4 5 23456 99999
#
# suits number_of_cells
#     1               2
#     2               6
#     3              12
#     4              20
#     5              30
#     6              42
#     7              56

require 'launchy'
require 'pathname'

def path(edges, src, dst, proh)
  if src == dst
    return [dst]
  end
  edges[src].each{ |e|
    if !proh.include?(e)
      k = path(edges, e, dst, proh + [src])
      if k != nil
        return [src] + k
      end
    end
  }
  return nil
end


def bimatch(edges)
  n = edges.size
  a = []
  b = []
  edges.each_with_index { |node, i|
    node.each { |edge|
      a.push(i)
      b.push(edge)
    }
  }
  a.uniq!
  b.uniq!
  edges.push(a)
  edges.push([])
  b.each { |i|
    edges[i].push(n + 1)
  }
 
  for i in 0..n + 1
    edges[i].shuffle!
  end
 
  p = 1
  loop do
    p = path(edges, n, n + 1, [])
    break if p == nil
    for i in 0 .. p.size - 2
      edges[p[i]].delete(p[i + 1])
      edges[p[i + 1]].push(p[i])
    end
  end
 
  edges.pop
  edges.pop
  for i in 0..n - 1
    edges[i].delete(n)
    edges[i].delete(n + 1)
  end
  return edges
end


def domino_puzzle(x, y, v)
  n = x * y
  vn = v.length
  if n < 2 || n % 2 == 1 || vn < 0 || vn * (vn + 1) < x * y
    return nil
  end
 
  tiles = []
  suits = v.split("").map{|e| e.to_i }.shuffle
 
  for i in 0...vn
    for j in i...vn
      tiles.push([suits[i], suits[j]].shuffle)
    end
  end
  tiles.shuffle!
 
  edges = []
  for i in 0...n
    node = []
    if (i % x + i / x) % 2 == 0
      if 0 < i % x
        node.push(i - 1)
      end
      if i % x < x - 1
        node.push(i + 1)
      end
      if 0 < i / x
        node.push(i - x)
      end
      if i / x < y - 1
        node.push(i + x)
      end
    end
    edges.push(node)
  end
 
  edges = bimatch(edges)
 
  mat = []
  rot = []
  ans = []
  for i in 0...y
    mat[i] = []
    rot[i] = []
    ans[i] = []
  end

  for i in 0...n
    if (i % x + i / x) % 2 == 1
      t = tiles.pop
      m = edges[i][0]
      c = (0...5).to_a # 1 x 2の敷き詰めは貪欲5彩色可能
      ix = i / x
      iy = i % x
      mx = m / x
      my = m % x
      mat[ix][iy] = t[0]
      mat[mx][my] = t[1]
      if ix == mx
        rot[ix][iy] = 1
        rot[mx][my] = 1
      else
        rot[ix][iy] = 0
        rot[mx][my] = 0
      end
      diff = [[0, 1], [1, 0], [0, -1], [-1, 0]]
      diff.each{ |e|
        if ans[ix + e[0]] != nil
          c.delete(ans[ix + e[0]][iy + e[1]])
        end
        if ans[mx + e[0]] != nil
          c.delete(ans[mx + e[0]][my + e[1]])
        end
      }
      ans[ix][iy] = c[0]
      ans[mx][my] = c[0]
    end
  end
 
  return {:mat => mat, :rot => rot, :ans => ans}
end

fname = ARGV[0]
x = ARGV[2].to_i
y = ARGV[1].to_i
v = ARGV[3]
if ARGV[4] != nil
  srand(ARGV[4].to_i)
end

pz = domino_puzzle(x, y, v)

fpath = Pathname(File.expand_path(fname, __dir__))

File.open(fpath, "w"){ |html|
  html.puts("<!DOCTYPE html><head><link rel='stylesheet' type='text/css' href='#{Pathname(File.expand_path('domino.css', __dir__)).relative_path_from(fpath.dirname).to_s}'></style><head><html><body>")
  if pz == nil
    html.puts("<p>impossible</p>")
  else
    p = pz[:mat]
    r = pz[:rot]
    a = pz[:ans]
    html.puts("<div>")
    html.puts((0...y).map{ |i|
      (0...x).map{ |j|
        "<div class = 'default-color'><div class = 'r#{r[i][j]}'><div class = 'cell d#{p[i][j]}'>#{p[i][j]}</div></div></div>"
      }.join("")
    }.join("<br>"))
    html.puts("</div><br>")
  
    html.puts("<input type = 'checkbox' id = 'check' /><label for='check'>show an answer</label><br><div class = 'answer'>")
    html.puts((0...y).map{ |i|
      (0...x).map{ |j|
        "<div class = 'c#{a[i][j]}'><div class = 'r#{r[i][j]}'><div class = 'cell d#{p[i][j]}'>#{p[i][j]}</div></div></div>"
      }.join("")
    }.join("<br>"))
    html.puts("</div>")
  end
  html.puts("<pre>params: #{y} #{x} #{v} #{srand(0)}</pre></body></html>")
}

Launchy.open(fpath.to_s)
