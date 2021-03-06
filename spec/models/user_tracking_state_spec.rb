require 'spec_helper'

describe UserTrackingState do

  let(:user) do
    Fabricate(:user)
  end

  let(:post) do
    Fabricate(:post)
  end

  it "correctly gets the tracking state" do
    report = UserTrackingState.report([user.id])
    report.length.should == 0

    new_post = post

    report = UserTrackingState.report([user.id])

    report.length.should == 1
    row = report[0]

    row.topic_id.should == post.topic_id
    row.highest_post_number.should == 1
    row.last_read_post_number.should be_nil
    row.user_id.should == user.id

    # lets not leak out random users
    UserTrackingState.report([post.user_id]).should be_empty

    # lets not return anything if we scope on non-existing topic
    UserTrackingState.report([user.id], post.topic_id + 1).should be_empty

    # when we reply the poster should have an unread row
    Fabricate(:post, user: user, topic: post.topic)

    report = UserTrackingState.report([post.user_id, user.id])
    report.length.should == 1

    row = report[0]

    row.topic_id.should == post.topic_id
    row.highest_post_number.should == 2
    row.last_read_post_number.should == 1
    row.user_id.should == post.user_id

    # when we have no permission to see a category, don't show its stats
    category = Fabricate(:category, secure: true)

    post.topic.category_id = category.id
    post.topic.save

    UserTrackingState.report([post.user_id, user.id]).count.should == 0
  end
end
