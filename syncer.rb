class Syncer
  attr_accessor :name, :bucket, :library
  def initialize(name, bucket, library)
    @bucket = bucket
    @name = name
    @library = library
  end

  def sync(files)
    upload_all_local(files)
    download_remote_files
    clean_local_files
  end

  private

  def download_remote_files
    local_files = library['files']
    bucket.objects.each do |object|
      file_name = object.key
      file_key = file_name.start_with?(name) ? file_name[(name.length+1)..-1] : file_name
      if local_files[file_key]
        if File.exist?(file_key)
          local_files[file_key] = 2
        else
          local_files.delete(file_key)
          object.delete
        end
      else
        object.download_file(file_name)
        local_files[file_key] = 2
      end
    end
  end

  def clean_local_files
    library['files'].each do |file, value|
      if value == 2
        library['files'][file] = 1
      else
        puts "should Delete file #{file}"
        library['files'].delete(file)
        FileUtils.rm(file) if File.exist?(file)
      end
    end
  end

  def upload_all_local(files)
    number_of_files = files.length
    files.each_with_index do |file, i|
      next if library['files'][file]
      print "#{i}/#{number_of_files}"
      print "\r"
      upload_file(file, name)
      library['files'][file] = 2
    end
    puts "Uploaded files"
  end

  def content_type(file_path)
    return 'image/jpeg' if file_path.end_with?('.jpg')
  end

  def upload_file(file_path, prefix)
    return if bucket.object("#{prefix}-#{file_path}").exists?
    bucket.object("#{prefix}-#{file_path}").upload_file(file_path, {content_type: content_type(file_path)})
  end
end