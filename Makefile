GIT=git

nothing:
	@echo "What do you want to make today? Choices:"
	@echo "	update-master (update master from next)"
	@echo "	update-next (update next from master)"

update-master:
	$(GIT) checkout master
	$(GIT) merge next
	$(GIT) checkout next
	$(GIT) gc
	$(GIT) push

update-next:
	$(GIT) checkout next
	$(GIT) merge master
	$(GIT) checkout master
	$(GIT) gc
	$(GIT) push

