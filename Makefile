clean: ## Remove *xcodeproj and .DS_Store files
	@rm -rf MeusCorreios.xcodeproj
	@find . -name '.DS_Store' -type f -delete

generate: ## Regenerate the Xcode project from project.yml
	@bash ./Scripts/killXcode.sh $(close)
	@rm -rf MeusCorreios.xcodeproj
	@find . -name '.DS_Store' -type f -delete
	@xcodegen generate
	@bash ./Scripts/posGenerate.sh $(open)
