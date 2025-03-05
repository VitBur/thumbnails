module Enumerable
  def divide_all_by(divisor)
    self.map { |element| element / divisor.to_f }
  end 
end


module ImageCompareHelpers
  def mean_squared_difference(img1, img2)
    sum_squared_dist = 0
    img1.columns.times { |x|
      img1.rows.times { |y| 
        pixel1 = img1.pixel_color(x, y)
        r1, g1, b1 = [pixel1.red, pixel1.green, pixel1.blue].divide_all_by(257)
        pixel2 = img2.pixel_color(x, y)
        r2, g2, b2 = [pixel2.red, pixel2.green, pixel2.blue].divide_all_by(257)
        sum_squared_dist += (r1 - r2) ** 2 + (g1 - g2) ** 2 + (b1 - b2) ** 2
      }
    }

    total_pixels = img1.columns * img1.rows
    sum_squared_dist / (total_pixels * 3)
  end

  def psnr(img1, img2)
    msd = mean_squared_difference(img1, img2)
    10 * Math.log10((255 ** 2) / msd)
  end
end 
    