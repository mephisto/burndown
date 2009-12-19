#add round to a number of decimal places to float
class Float
    alias_method :round_orig, :round
    def round_s(n=0)
        sprintf "%.#{n}%", self
    end
end