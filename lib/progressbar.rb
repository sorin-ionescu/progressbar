# encoding: UTF-8
if RUBY_VERSION =~ /1\.8/
  $KCODE = 'U'
  require 'jcode'
end

require 'terminfo'

module SI
  VERSION = "1.0.1"

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
      @finished = false
      @start_time = Time.now
      @previous_progress_time = @start_time
      @output_info = optional[:output_info] || [:percentage, :bar, :status]
      @output_format = optional[:output_format]

      unless @output_format
        if @output_info.include? :label
          @output_format = "%-#{@label.length}s: %003d%% %s %s"
        else
          @output_format = "%003d%% %s %s"
        end
      end

      self.file_mode = true if optional[:file_mode]
    end

    attr_reader :label
    attr_reader :current_progress
    attr_reader :total_progress
    attr_reader :start_time
    attr_accessor :fill
    attr_accessor :emtpy
    attr_accessor :output_info
    attr_accessor :output_format

    private
    # Dummy method
    def format_percentage
      percentage
    end

    def format_bar(output_length = 0)
      terminal_width = TermInfo.screen_size[1]
      if output_length > terminal_width
        spill = output_length - terminal_width
      else
        spill = 0
      end
      format = '|%s%s|'
      spill += 2 # The 2 bars ||
      fill_length = percentage * (terminal_width - spill) / 100
      return '' if fill_length < 0
      filled = @fill * fill_length
      empty = @empty * (terminal_width - fill_length - spill)
      sprintf("|%s%s|", filled, empty)
    end

    def format_status
      if @finished then format_elapsed else format_eta end
    end

    def format_status_file
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
      output = nil
      2.times do
        formatted_output = []
        @output_info.each do |info|
          method = sprintf("format_%s", info)

          if output and info == :bar
            if RUBY_VERSION =~ /1\.8/
              formatted_output << send(method, output.jlength)
            else
              formatted_output << send(method, output.length)
            end
          else
            formatted_output << send(method)
          end
        end
        output = sprintf(@output_format, *formatted_output)
      end

      @previous_progress_time = Time.now
      "\r\e[0K#{output}"
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

    def file_mode
      index = @output_info.index(:status_file)
      if index then true else false end
    end

    def file_mode=(value)
      @output_info.uniq!
      if value
        index = @output_info.index(:status)
        @output_info[index] = :status_file if index
      else
        index = @output_info.index(:status_file)
        @output_info[index] = :status if index
      end
    end
  end

  class ReverseProgressBar < ProgressBar
    def percentage
      100 - super
    end
  end
end

