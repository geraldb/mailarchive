#######################################
#  quick & dirty mbox (mail archive parser / exporter)
#


require 'cocos'
require 'strscan'




class Mailbox
  def self.read( path )
    txt = read_text( path )
    new( txt )
  end

  def initialize( txt )
    @msg = _parse( txt ).map {|m| Mail.new( m ) }
  end

  def _parse( txt )
    msg = []

    last_line = "\n"
    txt.each_line do |line|
      if last_line == "\n" && line =~ /\AFrom /
         puts "==> no.#{msg.size+1}"
         puts line
         msg << line
      else
         msg[-1] << line
      end
      last_line = line
    end
    msg
  end


  def export( basedir )
     ## sort by date
     msg = @msg.sort {|l,r|  r.date <=> l.date }

     buf = String.new('')
     buf << "# Mailbox Archive\n\n"

     files = Hash.new(0)

     msg.each_with_index do |m,i|
        puts "==> #{i+1}"
        date =  m.date

        name = date.strftime( '%Y-%m-%d' )
        count =  files[ name ] += 1

        path = "#{date.year}/#{name}_#{'%03d' % count}.txt"

        m.save( "#{basedir}/#{path}" )

        ## add summary readme
        buf << m.header( 'Date' )
        buf << "<br>\n"
        buf << (m.header( 'Subject', required: false ) || 'Subject: -')
        buf << "<br>\n"
        buf << m.header( 'From' )
        buf << "<br>\n"

        buf << "[More »](#{path})"
        buf << "\n\n"
     end

     write_text( "#{basedir}/README.md", buf )
  end

  def dump
    @msg.each_with_index do |m,i|
      puts "==> #{i+1}"
      puts m.header( 'Date' )
      date =  m.date
      puts date
      puts m.header( 'Subject', required: false ) || 'Subject: -'
      puts m.header( 'From' )
    end
  end

  def size()  @msg.size; end
  def []( index ) @msg[ index ]; end

end  # class Mailbox



class Mail
  def initialize( txt )
    @txt = txt
  end

  def to_s() @txt; end
  alias_method :text, :to_s

##
## From 66843574272@xxx Sat Dec 20 19:01:40 +0000 2014

##
##  Date: Sun, 4 Jan 2015 10:34:00 +0100
##
##  DateTime.rfc2822('Sat, 3 Feb 2001 04:05:06 +0700')

  def header( key, required: true  )
      ## find date header & parse
      rx = %r{^#{key}: .+$}
     if (m = @txt.match( rx ))
       m[0]
     else
       if required
         puts "!! ERROR - no #{key} header found; sorry"
         exit 1
       else
         nil
       end
     end
  end


  def date
     ## convert to date obj
     str = header( 'Date' ).sub( 'Date:', '' ).strip
     ## note: use new_offset to convert to utc!!
     DateTime.strptime( str, '%a, %d %b %Y %H:%M:%S %z' ).new_offset(0)
  end

  def write( path )
     write_text( path, @txt )
  end
  alias_method :save, :write
end   #  class Mail



basedir = './Takeout/Groups/googlegroups.com/ownedgroups'

groups = [
  'beerdb',
  'openmundi',
  'opensport',
  'wwwmake'
]

groups.each do |group|

  path = "#{basedir}/#{group}@googlegroups.com/topics.mbox"
  mbox = Mailbox.read( path )

  puts "  #{mbox.size} message(s)"

  mbox.dump
  ## mbox.export( "./tmp/#{group}" )
  mbox.export( "./#{group}" )


  puts "---"
  puts mbox[-1].text
  puts "---"
  puts mbox[-2].text
end

puts "bye"
