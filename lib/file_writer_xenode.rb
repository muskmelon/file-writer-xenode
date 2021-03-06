# Copyright Nodally Technologies Inc. 2013
# Licensed under the Open Software License version 3.0
# http://opensource.org/licenses/OSL-3.0

class FileWriterXenode
  include XenoCore::NodeBase
  
  # this method get call once as the Xenode is initialized
  # it is called inside the main eventmachine loop
  def startup()
    mctx = "#{self.class}.#{__method__} [#{@xenode_id}]"
    
    # this will always be logged as the force logging parameter is true
    do_debug("#{mctx} - config: #{@config.inspect}")
    
    # default if config not supplied
    @config ||= {}
    
  end
  
  def process_message(msg)
    mctx = "#{self.class}.#{__method__} [#{@xenode_id}]"
    begin
      # make sure there is an actual message as the system will read the
      # xenode's message queue on startup
      if msg
                
        # get the file_path from the message context
        fp = get_file_path(msg.context)
        
        # set file over write or append mode
        fmode = @config[:file_mode]
        fmode ||= "w"
                
        if msg.data
          File.open(fp, fmode) { |f|
             f.write(msg.data)
           }
          do_debug("#{mctx} writing file: #{fp.inspect}", true)
        end
        
      end
    rescue Exception => e
      catch_error("#{mctx} - ERROR #{e.inspect}")
    end
  end
  
  def get_file_path(context)
    mctx = "#{self.class}.#{__method__} [#{@xenode_id}]"
    ret_val = nil
    begin
      
      dir_path = nil
      file_name = nil
      
      # get the file_name
      file_name = get_file_name(context)
      
      do_debug("#{mctx} file_name: #{file_name.inspect}", true)
      
      # get the dir_path from the context
      dir_path = context['dir_path'] if context && context.is_a?(Hash)
      
      # resolve tokens in path ('@this_node' or '@this_server')
      dir_path = resolve_sys_dir(dir_path) if dir_path
      
      # set the default dir_path from config if none provided in context
      dir_path ||= resolve_sys_dir(@config[:dir_path])
      
      # set the default dir_path if none provided in config
      dir_path ||= resolve_sys_dir("@this_node")
      
      # ensure the directroy exists
      FileUtils.mkdir_p(dir_path) unless dir_path.to_s.empty?
      
      # join the path and file_name
      ret_val = File.join(dir_path, file_name)
      
    rescue Exception => e
      catch_error("#{mctx} - ERROR #{e.inspect}")
    end
    ret_val
  end
  
  def get_file_name(context)
    mctx = "#{self.class}.#{__method__} [#{@xenode_id}]"
    
    file_name = nil
    stamp = nil
    
    # get the file_name from the config
    file_name = @config[:file_name]
    
    # get filename from message context overrride config
    file_name = context[:file_name] if context && context[:file_name]
    
    # resolve the timestamp if any
    if file_name && file_name.to_s.include?("|TIMESTAMP|")
      stamp_format = @config[:stamp_format]
      stamp_format ||= "%Y%m%d%H%M%S%4N"
      file_name = file_name.gsub("|TIMESTAMP|", Time.now.strftime(stamp_format))
    end
      
    # set a default filename if none provided in the config
    file_name ||= "#{@xenode_id}_#{Time.now.strftime('%Y%m%d%H%M%S%4N')}_in"
        
    file_name
  end
end