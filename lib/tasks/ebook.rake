# encoding: utf-8

# Copyright (C) 2012  TEA, the ebook alternative <http://www.tea-ebook.com/>
# 
# This file is part of TeaBook Open Reader
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3.0 of the License.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# 
# An additional permission has been granted as a special exception 
# to the GNU General Public Licence. 
# You should have received a copy of this exception. If not, see 
# <https://github.com/TEA-ebook/teabook-open-reader/blob/master/GPL-3-EXCEPTION>.

namespace :ebook do

  namespace :import do

    desc "Import epubs from examples/ebooks"
    task :epub => [:environment] do
      u = User.last
      User.create! unless u
      src = File.join(Rails.root, "examples/ebooks")
      Dir.glob(File.join(src, '*.epub')).each do |epub_path|
        e = Ebook::Epub.create!(file: File.open(epub_path), source: 'upload', format: 'epub')
        User.all.each do |u|
          e.update_attribute :user_ids, [u.id]
          u.create_uploaded_purchase! e
        end
      end
    end
  end
  
  desc "Export an ebook to tea format"
  task :export => [:environment] do
    epub = Ebook::Epub.new(:file => File.open(ARGV[1]))
    export_directory = ""
    FileUtils.mkdir_p "export/#{epub.id.to_s}/components"
    FileUtils.mkdir_p "db/epub/#{epub.id.to_s[0..11]}/#{epub.id.to_s[12..23]}"
    begin
      epub.extract
    rescue Exception => e
      pp e
    end
    puts "==> HTML"
    begin
      epub.convert_to_html
    rescue Exception => e
      pp e
    end
    File.open("export/#{epub.id.to_s}/meta.json", 'w') do |f|
      f.write(epub.as_json(components: true, chapters: true).to_json)
    end
    epub.components.each do |component|
      File.open("export/#{epub.id.to_s}/components/#{component.id.to_s}.json", 'w') do |f|
        f.write(component.to_json)
      end
    end
  end
end
