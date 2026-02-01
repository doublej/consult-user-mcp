import { slides } from '../../../slides.js';

export function load({ params }: { params: { left: string; right: string } }) {
	return {
		left: slides[params.left],
		right: slides[params.right]
	};
}
