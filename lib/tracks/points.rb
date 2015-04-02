require 'median_filter'
require 'moving_average'

class TrackPoints
  attr_reader :points

  def initialize(track = nil)
    raise ArgumentError.new('Track must be present') if track.nil?

    @points = []
    @ff_start = 0
    @ff_end = 0

    read(track)
  end

  def trimmed
    track_points = @points.clone
    if @ff_start.present?
       track_points = track_points.drop_while{ |x| x[:fl_time_abs] < @ff_start}
    end
    if @ff_end.present? && @ff_end > 0 && (@ff_start.blank? || @ff_end > @ff_start)
      track_points = track_points.reverse.drop_while{ |x| x[:fl_time_abs] > @ff_end}.reverse
    end

    track_points
  end

  def trim_interpolize(range_from, range_to)
    track_points = []
    is_first = true
    prev_point = nil
    trimmed_points = trimmed

    trimmed.each do |curr|
      current_point = curr.clone

      is_last = true

      if current_point[:elevation] <= range_from && current_point[:elevation] >= range_to

        is_last = false

        if is_first

          is_first = false

          if current_point[:elevation] != range_from && prev_point.present?
            elev_diff = range_from - current_point[:elevation]
            k = elev_diff / current_point[:elevation_diff]
            current_point[:fl_time] = (current_point[:fl_time] * k).round(1)
            current_point[:distance] = (current_point[:distance] * k).round(0)
            current_point[:elevation_diff] = elev_diff

            track_points << current_point

          end

          next

        end

        track_points << current_point

      end

      if is_last && !track_points.empty?
        if current_point[:elevation] <= range_to
          elev_diff = prev_point[:elevation] - range_to
          k = elev_diff / current_point[:elevation_diff]
          current_point[:fl_time] = (current_point[:fl_time] * k).round(1)
          current_point[:distance] = (current_point[:distance] * k).round(0)
          current_point[:elevation_diff] = elev_diff

          track_points << current_point

        end
        break
      end

      prev_point = current_point
    end

    track_points
  end

  def min_h
    trimmed.min_by { |x| x[:elevation] }[:elevation]
  end

  def max_h
    trimmed.max_by { |x| x[:elevation] }[:elevation]
  end

  private

  def read(track)
    @ff_start = track.ff_start
    @ff_end = track.ff_end

    read_points(track)

    process_by_distances(@points)
    # @points = MedianFilter.process(@points,
                                   # 5,
                                   # [:h_speed, :v_speed])

    @points = MovingAverage.process(@points, 5, [:h_speed, :v_speed])

    calc_gr @points
  end

  def read_points(track)
    points = Point.joins(:tracksegment)
                  .where('tracksegments.track_id' => track.id).to_a

    prev_point = nil
    fl_time = 0

    points.each do |point|
      if prev_point

        fl_time_diff = point.point_created_at - prev_point.point_created_at
        fl_time += fl_time_diff

        elevation_diff = (prev_point.elevation - point.elevation).round(2)
        raw_h = Velocity.to_kmh(point.distance / fl_time_diff)
        raw_v = Velocity.to_kmh(elevation_diff) / fl_time_diff

        @points << { fl_time: fl_time_diff,
                     fl_time_abs: fl_time,
                     elevation_diff: elevation_diff,
                     elevation: point.elevation.round(2),
                     abs_altitude: point.abs_altitude,
                     latitude: point.latitude,
                     longitude: point.longitude,
                     distance: point.distance.to_i,
                     h_speed: (point.h_speed || 0.0).round,
                     v_speed: (point.v_speed || 0.0).round,
                     raw_h_speed: raw_h,
                     raw_v_speed: raw_v }

      end
      prev_point = point
    end
  end

  def process_by_distances(points)
    window_size = 5
    neighbors = (window_size / 2).floor
    temp = ([points.first] * neighbors) + points + ([points.last] * neighbors)

    temp.each_cons(window_size).map do |window|
      distance = window.map { |x| x[:distance] }.inject(0, :+)
      elevation = window.map { |x| x[:elevation_diff] }.inject(0, :+)
      # elevation = window.first[:elevation] - window.last[:elevation]
      fl_time = window.map { |x| x[:fl_time] }.inject(0, :+)

      window[neighbors][:h_speed] = distance / fl_time * 3.6
      window[neighbors][:v_speed] = elevation / fl_time * 3.6

      window[neighbors]
    end
  end

  def calc_gr points
    points.each do |p|
      p[:raw_gr] = p[:raw_v_speed] == 0 ? 0 : (p[:raw_h_speed] / p[:raw_v_speed]).round(2)
      p[:glrat] = (p[:h_speed].to_f / p[:v_speed]).round(2)
    end
  end
end