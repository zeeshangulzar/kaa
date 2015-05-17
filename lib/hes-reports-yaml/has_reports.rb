module HesReportsYaml
	module HasReports
		def has_reports
			self.send(:has_yaml_content, :reports)
			self.send(:has_yaml_content, :report_setup, :plural => false)
		end
	end
end