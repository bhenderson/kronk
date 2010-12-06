require 'test/test_helper'

class TestDiff < Test::Unit::TestCase

  def setup
    @diff = Kronk::Diff.new mock_302_response, mock_301_response
  end


  def test_new_from_data
    other_data = {:foo => :bar}

    diff = Kronk::Diff.new_from_data mock_data, other_data

    assert_equal Kronk::Diff.ordered_data_string(mock_data), diff.str1
    assert_equal Kronk::Diff.ordered_data_string(other_data), diff.str2
  end


  def test_ordered_data_string
    expected = <<STR
{
"acks"  => [
 [
  56,
  78
  ],
 [
  "12",
  "34"
  ]
 ],
"root"  => [
 [
  "B1",
  "B2"
  ],
 [
  "A1",
  "A2"
  ],
 [
  "C1",
  "C2",
  [
   "C3a",
   "C3b"
   ]
  ],
 {
  "test" => [
   [
    "D1a\\nContent goes here",
    "D1b"
    ],
   "D2"
   ],
  :tests => [
   "D3a",
   "D3b"
   ]
  }
 ],
"subs"  => [
 "a",
 "b"
 ],
"tests" => {
 "test" => [
  [
   1,
   2
   ],
  2.123
  ],
 :foo   => :bar
 }
}
STR

    assert_equal expected.strip, Kronk::Diff.ordered_data_string(mock_data)
  end


  def test_create_diff_inverted
    @diff = Kronk::Diff.new mock_301_response, mock_302_response
    assert_equal diff_301_302, @diff.create_diff
  end


  def test_create_diff
    assert_equal diff_302_301, @diff.create_diff
    assert_equal @diff.to_a, @diff.create_diff
    assert_equal @diff.to_a, @diff.diff_array
  end


  def test_create_diff_no_match
    str1 = "this is str1\nthat shouldn't\nmatch\nany of\nthe\nlines"
    str2 = "this is str2\nwhich should\nalso not match\nany\nof the\nstr1 lines"

    diff = Kronk::Diff.new str1, str2
    assert_equal [[str1.split("\n"), str2.split("\n")]], diff.create_diff
  end


  def test_create_diff_all_match
    str1 = "this is str\nthat should\nmatch\nall of\nthe\nlines"
    str2 = "this is str\nthat should\nmatch\nall of\nthe\nlines"

    diff = Kronk::Diff.new str1, str2
    assert_equal str1.split("\n"), diff.create_diff
  end


  def test_create_diff_all_added
    str1 = "this is str\nthat should\nmatch\nall of\nthe\nlines"
    str2 = "this is str\nmore stuff\nthat should\nmatch\nall of\nthe\nold lines"

    expected = [
      "this is str",
      [[], ["more stuff"]],
      "that should",
      "match",
      "all of",
      "the",
      [["lines"], ["old lines"]]
    ]

    diff = Kronk::Diff.new str1, str2
    assert_equal expected, diff.create_diff
  end


  def test_create_diff_all_removed
    str1 = "this is str\nmore stuff\nthat should\nmatch\nall of\nthe\nold lines"
    str2 = "this is str\nthat should\nmatch\nall of\nthe\nlines"

    expected = [
      "this is str",
      [["more stuff"], []],
      "that should",
      "match",
      "all of",
      "the",
      [["old lines"], ["lines"]]
    ]

    diff = Kronk::Diff.new str1, str2
    assert_equal expected, diff.create_diff
  end


  def test_create_diff_multi_removed
    str1 = "this str\nmore stuff\nagain\nshould\nmatch\nall of\nthe\nold lines"
    str2 = "this str\nthat should\nmatch\nall of\nthe\nlines"

    expected = [
      "this str",
      [["more stuff", "again", "should"], ["that should"]],
      "match",
      "all of",
      "the",
      [["old lines"], ["lines"]]
    ]

    diff = Kronk::Diff.new str1, str2
    assert_equal expected, diff.create_diff
  end


  def test_create_diff_long_end_diff
    str1 = "this str\nis done"
    str2 = "this str\nthat should\nmatch\nall of\nthe\nlines"

    expected = [
      "this str",
      [["is done"], ["that should", "match", "all of", "the", "lines"]],
    ]

    diff = Kronk::Diff.new str1, str2
    assert_equal expected, diff.create_diff
  end


  def test_create_diff_long_end_diff_inverted
    str1 = "this str\nthat should\nmatch\nall of\nthe\nlines"
    str2 = "this str\nis done"

    expected = [
      "this str",
      [["that should", "match", "all of", "the", "lines"], ["is done"]],
    ]

    diff = Kronk::Diff.new str1, str2
    assert_equal expected, diff.create_diff
  end


  def test_create_diff_long
    str1 = "this str"
    str2 = "this str\nthat should\nmatch\nall of\nthe\nlines"

    expected = [
      "this str",
      [[], ["that should", "match", "all of", "the", "lines"]],
    ]

    diff = Kronk::Diff.new str1, str2
    assert_equal expected, diff.create_diff
  end


  def test_create_diff_long_inverted
    str1 = "this str\nthat should\nmatch\nall of\nthe\nlines"
    str2 = "this str"

    expected = [
      "this str",
      [["that should", "match", "all of", "the", "lines"], []],
    ]

    diff = Kronk::Diff.new str1, str2
    assert_equal expected, diff.create_diff
  end


  def test_formatted
    assert_equal diff_302_301_str, @diff.formatted
  end


  def test_formatted_color
    assert_equal diff_302_301_color, @diff.formatted(:color_diff)

    @diff.format = :color_diff
    assert_equal diff_302_301_color, @diff.formatted
  end


  def test_formatted_join_char
    expected = diff_302_301_str.gsub(/\n/, "\r\n")
    assert_equal expected, @diff.formatted(:ascii_diff, "\r\n")
  end


  def test_formatted_block
    str_diff = @diff.formatted do |item|
      if Array === item
        item[0].map!{|str| "<<<302<<< #{str}"}
        item[1].map!{|str| ">>>301>>> #{str}"}
        item
      else
        item.to_s
      end
    end

    expected = diff_302_301_str.gsub(/^\+/, ">>>301>>>")
    expected = expected.gsub(/^\-/, "<<<302<<<")

    assert_equal expected, str_diff
  end

  private

  def diff_302_301
    [[["HTTP/1.1 302 Found", "Location: http://igoogle.com/"],
      ["HTTP/1.1 301 Moved Permanently", "Location: http://www.google.com/"]],
    "Content-Type: text/html; charset=UTF-8",
    "Date: Fri, 26 Nov 2010 16:14:45 GMT",
    "Expires: Sun, 26 Dec 2010 16:14:45 GMT",
    "Cache-Control: public, max-age=2592000",
    "Server: gws",
    [["Content-Length: 260"], ["Content-Length: 219"]],
    "X-XSS-Protection: 1; mode=block",
    "",
    "<HTML><HEAD><meta http-equiv=\"content-type\" content=\"text/html;charset=utf-8\">",
    [["<TITLE>302 Found</TITLE></HEAD><BODY>", "<H1>302 Found</H1>"],
      ["<TITLE>301 Moved</TITLE></HEAD><BODY>", "<H1>301 Moved</H1>"]],
    "The document has moved", "<A HREF=\"http://www.google.com/\">here</A>.",
    [["<A HREF=\"http://igoogle.com/\">here</A>."], []],
    "</BODY></HTML>"]
  end

  def diff_301_302
    [[["HTTP/1.1 301 Moved Permanently", "Location: http://www.google.com/"],
      ["HTTP/1.1 302 Found", "Location: http://igoogle.com/"]],
    "Content-Type: text/html; charset=UTF-8",
    "Date: Fri, 26 Nov 2010 16:14:45 GMT",
    "Expires: Sun, 26 Dec 2010 16:14:45 GMT",
    "Cache-Control: public, max-age=2592000",
    "Server: gws",
    [["Content-Length: 219"], ["Content-Length: 260"]],
    "X-XSS-Protection: 1; mode=block",
    "",
    "<HTML><HEAD><meta http-equiv=\"content-type\" content=\"text/html;charset=utf-8\">",
    [["<TITLE>301 Moved</TITLE></HEAD><BODY>", "<H1>301 Moved</H1>"],
      ["<TITLE>302 Found</TITLE></HEAD><BODY>", "<H1>302 Found</H1>"]],
    "The document has moved", "<A HREF=\"http://www.google.com/\">here</A>.",
    [[], ["<A HREF=\"http://igoogle.com/\">here</A>."]],
    "</BODY></HTML>"]
  end


  def diff_302_301_str
    str = <<STR
- HTTP/1.1 302 Found
- Location: http://igoogle.com/
+ HTTP/1.1 301 Moved Permanently
+ Location: http://www.google.com/
Content-Type: text/html; charset=UTF-8
Date: Fri, 26 Nov 2010 16:14:45 GMT
Expires: Sun, 26 Dec 2010 16:14:45 GMT
Cache-Control: public, max-age=2592000
Server: gws
- Content-Length: 260
+ Content-Length: 219
X-XSS-Protection: 1; mode=block

<HTML><HEAD><meta http-equiv="content-type" content="text/html;charset=utf-8">
- <TITLE>302 Found</TITLE></HEAD><BODY>
- <H1>302 Found</H1>
+ <TITLE>301 Moved</TITLE></HEAD><BODY>
+ <H1>301 Moved</H1>
The document has moved
<A HREF="http://www.google.com/">here</A>.
- <A HREF="http://igoogle.com/">here</A>.
</BODY></HTML>
STR
    str.strip
  end

  def diff_302_301_color
    str = <<STR
\033[31mHTTP/1.1 302 Found\033[0m
\033[31mLocation: http://igoogle.com/\033[0m
\033[32mHTTP/1.1 301 Moved Permanently\033[0m
\033[32mLocation: http://www.google.com/\033[0m
Content-Type: text/html; charset=UTF-8
Date: Fri, 26 Nov 2010 16:14:45 GMT
Expires: Sun, 26 Dec 2010 16:14:45 GMT
Cache-Control: public, max-age=2592000
Server: gws
\033[31mContent-Length: 260\033[0m
\033[32mContent-Length: 219\033[0m
X-XSS-Protection: 1; mode=block

<HTML><HEAD><meta http-equiv="content-type" content="text/html;charset=utf-8">
\033[31m<TITLE>302 Found</TITLE></HEAD><BODY>\033[0m
\033[31m<H1>302 Found</H1>\033[0m
\033[32m<TITLE>301 Moved</TITLE></HEAD><BODY>\033[0m
\033[32m<H1>301 Moved</H1>\033[0m
The document has moved
<A HREF="http://www.google.com/">here</A>.
\033[31m<A HREF="http://igoogle.com/">here</A>.\033[0m
</BODY></HTML>
STR
    str.strip
  end
end
