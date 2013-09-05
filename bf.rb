#!/usr/bin/ruby

def pp(*x)
#  STDERR.puts x.inspect
  x.first
end

$location = 0;

$debug = false;
$scratch = 50

$current_scratch = 0
$stack_vars = []

def lookup(sym)
  if sym.is_a? Symbol
   $vars.index(sym) + $scratch
  else
    sym
  end
end

def goto(sym)
  new = lookup(sym)
  if (new == $location)
  elsif (new > $location)
    print (if $debug then "(#{(new - $location)})" else "" end) + ">" * (new - $location)
  else
    print (if $debug then "(#{($location - new)})" else "" end) + "<" * ($location - new)
  end
  $location = new
end

def scratch(n = 1)
  cur_scratch = $current_scratch;
  $current_scratch += n
#  STDERR.puts "Scratch: #{$current_scratch}"
  yield *(pp((cur_scratch...$current_scratch).to_a))
  $current_scratch -= n
end


def zero(sym)
   goto(sym)
   print "[-]"
end

def sub(sym)
   goto(sym)
   print "-"
end
def add(sym)
   goto(sym)
   print "+"
end

def _loop(loc)
  goto(loc)
  print "["
  yield
  goto(loc)
  print "]"
end

def _if(loc)
   scratch{ |tmp|
     copy loc, tmp
     _loop(tmp){
       yield
       zero(tmp)
     }
   }
end

def set(sym1, n=1)
   goto(sym1)
   zero(sym1)
   print "(#{n})" if n > 2 && $debug
   n.times{ add sym1 }
end

def _putchar(sym)
   goto sym
   print "."
end

def _getchar(sym)
   zero(sym)
   goto sym
   print ","
end

def _putdig(sym)
   scratch{|tmp|
      set tmp, '0'.ord
      add2 sym, tmp
      _putchar tmp
   }
end
      

def _puts(str)
   scratch{|tmp|
      str.each_char{|x| set(tmp, x.ord); _putchar(tmp)}
   }
end


def move(sym1, sym2)
  _loop(sym1) {
    sub(sym1)
    add(sym2)
  }
end

def add2(sym1, sym2)
  scratch{|tmp|
    zero(tmp)
    _loop(sym1){
      sub(sym1)
      add(sym2)
      add(tmp)
    }
    move tmp, sym1
  }
end

def sub2(sym1, sym2)
  scratch{|tmp|
    zero(tmp)
    _loop(sym1){
      sub(sym1)
      sub(sym2)
      add(tmp)
    }
    move tmp, sym1
  }
end

def copy(sym1, sym2)
  zero(sym2)
  add2(sym1, sym2)
end

def _and(sym1, sym2, result)
  set(result, 0)
  _if(sym1) {
    _if(sym2) {
      set(result, 1)
    }
  }
end

def _not(sym, result)
  set(result, 1)
  _if(sym) {
    set(result, 0)
  }
end

def _if_not(sym)
  scratch(1) {|tmp|
    _not(sym, tmp)
    _if(tmp) {
      yield
    }
  }
end

def d(name, var)
  _puts name + ": "
  _putdig var
  _puts "\n" 
end

def equal(sym1, sym2, result)
  scratch(3){|a1, a2, a3|
    copy sym1, a2
    copy sym2, a3
    set(a1)
    _loop(a1) {
      set(a1, 0)
      _if(a2) {
        _if(a3) {
          set(a1)
          sub(a2)
          sub(a3)
        }
      }
    }
    set(result)
    _if(a2) {
      set(result, 0)
    }
    _if(a3) {
      set(result, 0)
    }
  }
end

def _if_equal(sym1, sym2)
  scratch{|result|
    equal(sym1, sym2, result)
    _if(result) {
      yield
    }
  }
end

def _if_equal_c(sym1, c)
  scratch{|tmp|
    set(tmp, c)
    _if_equal(sym1, tmp) {
      yield
    }
  }
end

def div(dividend, divisor, result, mod)
   zero(result)

   scratch(2){|dividend_copy, if_check|
     pp "asdf", dividend_copy
     copy dividend, dividend_copy
     copy divisor, mod
     _loop(dividend_copy){
       set(if_check, 0)
       _and(dividend_copy, mod, if_check)
       _if(if_check) {
         sub(dividend_copy)
         sub(mod)
       }
       _not(mod, if_check)
       _if(if_check) {
         _if(dividend_copy) {
           copy divisor, mod
         }
         #_puts "test"
         add(result)
       }
     }
     _if(mod) {
       copy mod, dividend_copy
       copy divisor, mod
       sub2 dividend_copy, mod
     }
   }
end

def put_num(sym)
   scratch(5){|num, divisor, result, if_check, carry|
     zero(if_check)
     set divisor, 100
     div sym, divisor, result, carry
     _if(result) {
       _putdig result
       set(if_check)
     }
     set divisor, 10
     div carry, divisor, result, num
     _if(result) {
       set(if_check)
     }
     _if(if_check) {
       _putdig result
     }
     _putdig num
  }
end

$arrays = 3;

def move__(n)
  if n > 0 then
    print"[" + "-" + ">" * n + "+" + "<" * n + "]"
  else 
    print"[" + "-" + "<" * -n + "+" + ">" * -n + "]"
  end
end

# *abcdef  -> f*abcde
def rrotate_swap(n)
  print ">" * n
  move__(-n)
  (n-1).times{
    print "<"
    move__ 1
  }
  print "<"
end

# f*abcde -> *abcdef
def lrotate_swap(n)
  print ">"
  (n-1).times{
    print ">"
    move__ -1
  }
  print "<" * n
  move__ n
end

$arrays = 3

def mm_move(sym1, payload_size, array)
  copy(sym1, lookup(:end) + 1)
  copy(sym1, lookup(:end) + 2)
  goto(lookup(:end) + 1)

  #move to value
  print "[-<"
  $arrays.times{
     rrotate_swap(3 + payload_size)
     print ">"
  }
  print ">]"

  print "<"
  array.times{
     rrotate_swap(3 + payload_size)
     print ">"
  }
  print ">"

  # @ rightinc
  # set value
  print ">>"
  yield
  print "<<"

  print "<"
  array.times{
     print "<"
     lrotate_swap(3 + payload_size)
  }
  print ">"

  # @ rightinc
  print ">"
  print "[-<<"
  $arrays.times{
     print "<"
     lrotate_swap(3 + payload_size)
  }
  print ">>]"
  print "<"
end
  
     
def set_mm(sym1, sym2, array)
  copy(sym2, lookup(:end) + 3)
  mm_move(sym1, 2, array) {
    print ">>[-]<<[->>+<<]"
  }
end


def get_mm(sym1, sym2, array)
  copy(sym2, lookup(:end) + 3)
  zero(lookup(:end) + 3)
  zero(lookup(:end) + 4)
  mm_move(sym1, 2, array) {
    print ">>[-<+<+>>]<[->+<]<"
  }
  copy(lookup(:end) + 3, sym2)
end
      


 
$vars = [:length, :a, :b, :c, :d, :end]



scratch(2){|loading, ch|

  set(loading)
  
  set(:length, 0)
  
  _loop(loading) {
    _getchar(ch)
    _if_equal_c(ch, "!".ord) {
      zero(loading)
    }
    
    _if(loading) {
      set_mm(:length, ch, 0)
      add(:length)
    }
  }
}


scratch(6){|running, pc, ptr, tmp, val, stack|
  zero(pc)
  zero(val)
  zero(ptr)
  zero(stack)
  set(running)
  _if_equal(pc, :length) {
    zero(running)
  }
  _loop(running) {
    get_mm(pc, tmp, 0)
    _if_equal_c(tmp, "+".ord) {
      add(val)
    }
    _if_equal_c(tmp, "-".ord) {
      sub(val)
    }
    _if_equal_c(tmp, ".".ord) {
      _putchar(val)
    }
    _if_equal_c(tmp, ",".ord) {
      _getchar(val)
    }
    _if_equal_c(tmp, ">".ord) {
      set_mm(ptr, val, 1)
      add(ptr)
      get_mm(ptr, val, 1)
    }
    _if_equal_c(tmp, "<".ord) {
      set_mm(ptr, val, 1)
      sub(ptr)
      get_mm(ptr, val, 1)
    }
    _if_equal_c(tmp, "[".ord) {
      _if(val) {
         set_mm(stack, pc, 2)
         add(stack) 
      }
      _if_not(val) {
         scratch(2) {|tmp2, ch1|
           set(tmp2, 1)
           _loop(tmp2) {
             add(pc)
             get_mm(pc, ch1, 0)
             _if_equal_c(ch1, "[".ord) {
               add(tmp2)
             }
             _if_equal_c(ch1, "]".ord) {
               sub(tmp2)
             }
           }
         }
      }
    }

    _if_equal_c(tmp, "]".ord) {
      _if(val) {
        sub(stack)
        get_mm(stack, pc, 2)
        add(stack)
      }
      _if_not(val) {
        sub(stack)
      }
    }

    _if_equal_c(tmp, "*".ord) {
      put_num(val)
    }
    add(pc)

    _if_equal(pc, :length) {
      zero(running)
    }
  }
}

exit
scratch(3){|count, i, ch|
  set(i, 0)
  copy(:length, count)
  _loop(count) {
    get_mm(i, ch, 0)
    _putchar(ch)
    add(i)
    sub(count)
  }
} 



exit

scratch(3){|count, i, ch|
  set(i, 0)
  copy(:length, count)
  _loop(count) {
    get_mm(i, ch, 0)
    _putchar(ch)
    add(i)
    sub(count)
  }
} 






exit

set(:a, 3)
set(:b, 4)
set(:c, 8)
set(:d, 9)
_putdig(:d)
set_mm(:a, :b, 1)
_putdig(:d)
set_mm(:a, :b, 1)
_putdig(:b)
get_mm(:a, :d, 1)
_putdig(:a)
_putdig(:d)

_puts("\n")

set(:a, 3)
set(:b, 4) 
equal(:a, :b, :c)
_if(:c) {
  _puts "fail test 1"
}
set(:b, 3)
equal(:a, :b, :c)
_putdig(:c)
_if(:c) {
  _puts "pass test 2"
}

puts
exit
set(:d, 10);
set(:a, 1)
put_num(:a)
_puts " "
put_num(:a)
_puts " "
set(:b, 1)
_loop(:d){
  set(:c, 0)
  add2(:a, :c)
  add2(:b, :c)
  put_num(:c)
  _puts " "
  copy(:a, :b)
  copy(:c, :a)
  sub(:d)
}
_puts "\n"
puts
