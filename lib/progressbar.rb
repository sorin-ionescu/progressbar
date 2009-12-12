require 'terminfo'

module SI
  VERSION = "1.0.0"
  
  class InvalidValueError < StandardError
  end
  
  class ProgressBar
    def initialize (total_progress, optional = {})
      @total_progress = total_progress
      @current_progress = 0
      @previous_progress = 0
      @fill = optional[:fill] || '='
      @empty = optional[:empty] || '.'
      @label = optional[:label] || nil
      @terminal_width = TermInfo.screen_size[1]
      @finished = false
      @start_time = Time.now
      @previous_progress_time = @start_time
      @output_format =
        output_format optional[:output_format],
        optional[:file_mode] || false
    end

    attr_reader :label
    attr_reader :current_progress
    attr_reader :total_progress
    attr_accessor :start_time

    private
    # Dummy method
    def format_percentage
      percentage
    end
    
    def format_bar(used)
      format = '|%s%s|'
      used += 2
      fill_length = percentage * (@terminal_width - used) / 100
      filled = @fill * fill_length
      empty = @empty * (@terminal_width - fill_length - used)
      sprintf("|%s%s|", filled, empty)
    end
    
    def format_status
      if @finished then format_elapsed else format_eta end
    end
    
    def format_status_file_mode
      if @finished 
        sprintf("%s %s %s", bytes, transfer_rate, format_elapsed)
      else 
        sprintf("%s %s %s", bytes, transfer_rate, format_eta)
      end
    end
    
    # Dummy function
    def format_label
      @label
    end

    def format_bytes (value)
      if value < 1024
        sprintf("%6dB", value)
      elsif value < 1024 * 1000
        sprintf("%5.1fKiB", value.to_f / 1024)
      elsif value < 1024 * 1024 * 1000
        sprintf("%5.1fMiB", value.to_f / 1024 / 1024)
      else
        sprintf("%5.1fGiB", value.to_f / 1024 / 1024 / 1024)
      end
    end
    
    def bytes
      format_bytes(@current_progress)
    end
    
    def transfer_rate
      bytes_per_second = @current_progress.to_f / (Time.now - @start_time)
      sprintf("%s/s", format_bytes(bytes_per_second))
    end
    
    def format_time (time)
      time = time.to_i
      second = time % 60
      minute  = (time / 60) % 60
      hour = time / 3600
      sprintf("%02d:%02d:%02d", hour, minute, second);
    end

    def format_eta
      if @current_progress == 0
        "ETA: --:--:--"
      else
        elapsed = Time.now - @start_time
        eta = elapsed * @total_progress / @current_progress - elapsed;
        sprintf("ETA: %s", format_time(eta))
      end
    end

    def format_elapsed
      elapsed = Time.now - @start_time
      sprintf("Time: %s", format_time(elapsed))
    end
    
    public
    def to_s
      formatted_output = {}
      used_character_count = 0
      
      @output_format.each do |key, value|
        if key == :bar
          formatted_entry = sprintf(value, '')
        else
          method = sprintf("format_%s", key)
          formatted_entry = sprintf(value, send(method))
        end
        used_character_count += formatted_entry.length
        formatted_output[key] = formatted_entry
      end
      
      if formatted_output.has_key? :bar
        formatted_output[:bar] = 
          sprintf(@output_format[:bar], format_bar(used_character_count))
      end
 
      output = ""
      formatted_output.values.each do |value|
        output += value if value
      end
      
      @previous_progress_time = Time.now
      output
    end
    
    def percentage
      return (@current_progress.to_f / @total_progress.to_f * 100).round
    end
    
    def finish
      @current_progress = @total_progress
      @finished = true
      return self
    end
    
    def finished?
      @finished
    end
    
    def file_transfer_mode
      output_format nil, true
    end
    
    def halt
      @finished = true
      return self
    end
    
    def inc (value = 1)
      @current_progress += value
      @current_progress = @total_progress if @current_progress > @total_progress
      @previous_progress = @current_progress
      return self
    end
    
    def set (value)
      if value < 0 || value > @total_progress
        raise InvalidValueError.new
          "Invalid value: #{value} (total: #{@total_progress})"
      end
      @current_progress = value
      @previous_progress = @current_progress
      return self
    end
    
    def inspect
      "#<ProgressBar:#{@current_progress}/#{@total_progress}>"
    end
    
    def output_format
      @output_format
    end
    
    def output_format(format, file_mode=false)
      if format
        @output_format = format
        return
      end
      
      if file_mode
        status = :status_file_mode
      else
        status = :status
      end
      
      if @label
        @output_format = {
          :label => "%-#{@label.length}s:",
          :percentage => " %003d%%",
          :bar => " %s",
          status => " %s"}
      else
        @output_format = {
          :percentage => "%003d%%",
          :bar => " %s",
          status => " %s"}
      end
    end
  end
  
  class ReverseProgressBar < ProgressBar
    def percentage
      100 - super
    end
  end
end
