#include "stream_peer_file.h"

using namespace godot;

void StreamPeerFile::_bind_methods() {
	ClassDB::bind_method(D_METHOD("get_file_access"), &StreamPeerFile::get_file_access);
	ClassDB::bind_static_method("StreamPeerFile", D_METHOD("open", "path", "mode"), &StreamPeerFile::open);
	ClassDB::bind_static_method("StreamPeerFile", D_METHOD("from", "fd"), &StreamPeerFile::from);
}

Error StreamPeerFile::_get_data(uint8_t* r_buffer, const int32_t r_bytes, int32_t* r_received) {
	int32_t received;
	_get_partial_data(r_buffer, r_bytes, &received);
	if (received != r_bytes) {
		return ERR_INVALID_PARAMETER;
	}

	return OK;
}

Error StreamPeerFile::_get_partial_data(uint8_t* r_buffer, const int32_t r_bytes, int32_t* r_received) {
	*r_received = m_fd->get_buffer(r_buffer, r_bytes);
	return OK;
}

Error StreamPeerFile::_put_data(const uint8_t* p_data, const int32_t p_bytes, int32_t* r_sent) {
	m_fd->store_buffer(p_data, p_bytes);
	*r_sent = p_bytes;
	return OK;
}

Error StreamPeerFile::_put_partial_data(const uint8_t* p_data, const int32_t p_bytes, int32_t* r_sent) {
	return _put_data(p_data, p_bytes, r_sent);
}

int32_t StreamPeerFile::_get_available_bytes() const { return m_fd->get_length() - m_fd->get_position(); }

StreamPeerFile* StreamPeerFile::open(const String& p_path, const FileAccess::ModeFlags p_mode) {
	StreamPeerFile* const stream_peer = memnew(StreamPeerFile);
	stream_peer->m_fd = FileAccess::open(p_path, p_mode);
	ERR_FAIL_NULL_V(stream_peer->m_fd, nullptr);
	return stream_peer;
}

StreamPeerFile* StreamPeerFile::from(const Ref<FileAccess>& p_fd) {
	StreamPeerFile* const stream_peer = memnew(StreamPeerFile);
	stream_peer->m_fd = p_fd;
	return stream_peer;
}
